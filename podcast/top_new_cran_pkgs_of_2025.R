box::use(
  cranlogs[cran_downloads],
  dplyr[
    add_count, arrange, count, desc, distinct, filter, group_by, left_join, mutate, rename,
    row_number, rowwise, select, summarise
  ],
  ellmer[chat_claude, chat_google_gemini, chat_openai, params],
  ggplot2[
    aes, element_blank, element_text, geom_col, geom_text, geom_tile, ggplot, labs,
    scale_fill_gradient, scale_x_date, theme, theme_minimal
  ],
  jsonlite[fromJSON, toJSON],
  lubridate[as_date, floor_date],
  purrr[map_dfr],
  rvest[html_element, html_elements, html_table, html_text, read_html],
  tidyr[fill, pivot_longer, pivot_wider]
)

### Setear LLMs.
# Crear nuevas instancias de LLM para que tengamos sesiones de chat vacías.
ask_llms <- function(prompt) {
  system_prompt <- paste0(
    "Eres un experto evaluador de paquetes de R. ",
    "Debes elegir el top mejores paquetes."
  )
  llms <- list(
    # Claude no soporta la seed por el momento, igual dejemos el param por si lo hace en un futuro.
    Claude = chat_claude(
      system_prompt,
      model = "claude-3-haiku-20240307", params = params(seed = 881918)
    ),
    Gemini = chat_google_gemini(
      system_prompt,
      model = "gemini-2.5-flash", params = params(seed = 881918)
    ),
    OpenAI = chat_openai(
      system_prompt,
      model = "gpt-5-mini", params = params(seed = 881918)
    )
  )
  lapply(llms, function(llm) {
    suppressWarnings(reply <- llm$chat(prompt))
    message("Spent: $", llm$get_cost())
    list(reply = reply, cost = llm$get_cost())
  })
}

### Obtener paquetes publicados el 2025.
packages <- read_html(
  # Aquí se obtiene la fecha de actualización de cada paquete (no la fecha de lanzamiento).
  "https://cran.r-project.org/web/packages/available_packages_by_date.html"
) |> html_table()
packages <- mutate(
  packages[[1]],
  Date = as_date(Date),
  url = paste0("https://cran.r-project.org/web/packages/", Package, "/index.html"),
  readme_url = paste0(
    "https://cran.r-project.org/web/packages/", Package, "/readme/README.html"
  )
)
cranberries <- read_html("https://dirk.eddelbuettel.com/cranberries/2025/") |>
  html_elements(".package") |>
  map_dfr(function(elem) {
    data.frame(
      Package = html_text(html_elements(elem, "b")),
      ReleaseDate = html_text(html_element(
        elem,
        xpath = ".//strong[contains(., 'Date/Publication')]/following-sibling::text()[1]"
      ))
    )
  }) |>
  filter(grepl("^New package ", Package)) |>
  mutate(
    Package = gsub(" .*", "", gsub("^New package ", "", Package)),
    ReleaseDate = as_date(ReleaseDate)
  ) |>
  # Discard duplicates (it happens with some pkgs).
  arrange(ReleaseDate) |>
  distinct(Package, .keep_all = TRUE)
mutate(cranberries, ReleaseMonth = floor_date(ReleaseDate, "month")) |>
  count(ReleaseMonth) |>
  ggplot(aes(x = ReleaseMonth, y = n)) +
  geom_col(fill = "steelblue", color = "white", linewidth = 0.2) +
  geom_text(aes(label = n), vjust = -0.5, size = 3.5) +
  scale_x_date(date_labels = "%b", date_breaks = "1 month") +
  labs(
    title = paste0("New Packages per Month (", nrow(cranberries), ")"),
    x = "Month",
    y = "Number of Releases",
    caption = "Source: https://dirk.eddelbuettel.com/cranberries/2025/"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )
pkgs_of_year <- filter(packages, Package %in% cranberries$Package)
cat("Se encontraron", nrow(cranberries), "paquetes nuevos para 2025.")

### Obtener número de descargas por paquete.
downloads <- map_dfr(
  split(pkgs_of_year$Package, ceiling(seq_along(pkgs_of_year$Package) / 100)),
  function(pkgs) cran_downloads(pkgs, from = "2025-01-01", to = "2025-12-31")
)
downloads <- filter(downloads, count > 0) |>
  group_by(package) |>
  fill(count) |>
  summarise(downloads = sum(count), daily_downloads_mean = round(mean(count))) |>
  arrange(desc(daily_downloads_mean))
downloads

### Obtener el top-10 de cada mes.
dates <- format(seq.Date(as_date("2025-01-01"), as_date("2025-12-01"), by = "month"), "%Y%m")
pkgs_of_year <- map_dfr(dates, function(date) {
  page <- read_html(paste0("podcast/outputs/top_new_cran_pkgs_", date, ".html"))
  html_element(page, "#resultados-finales") |>
    html_table() |>
    mutate(Fecha = date)
})

### Leer la página de cada paquete y su README.
read_page <- function(url) {
  tryCatch(html_text(read_html(url)), error = function(e) NA_character_)
}

pkgs_of_year <- mutate(
  pkgs_of_year,
  url = paste0("https://cran.r-project.org/web/packages/", Paquete, "/index.html"),
  readme_url = paste0(
    "https://cran.r-project.org/web/packages/", Paquete, "/readme/README.html"
  )
)
system.time({
  pkgs_of_year <- mutate(
    rowwise(pkgs_of_year),
    page_content = read_page(url), readme_content = read_page(readme_url)
  )
})

### Pedir a los LLM que preseleccionen los mejores paquetes por su página de CRAN.
# Esto se debe a que si no preseleccionamos, entonces tenemos 120 paquetes para enviar a LLM.
preselect_n <- 25
prompt <- paste0(
  "De la lista de paquetes que te doy, debes hacer un pre-filtrado de ", preselect_n, " paquetes. ",
  "Devuelveme solo el nombre de los paquetes de los cuales te gustaria obtener mas informacion. ",
  'Da tu respuesta en formato JSON (`["PAQ_1", ..., "PAQ_N"]`).',
  "Esta es la lista de los paquetes que puedes seleccionar ",
  "(los paquetes que elijas, deben estar en esta lista (como campo `Package`):\n",
  "```json\n",
  toJSON(pkgs_of_year$page_content),
  "\n```"
)

preselection_replies <- ask_llms(prompt)
sapply(preselection_replies, function(x) x$cost)
preselection <- lapply(preselection_replies, function(x) {
  unique(fromJSON(gsub("\\].*", "]", gsub(".*\\[", "[", x$reply))))
})
stopifnot(all(
  sapply(preselection, function(x) length(intersect(x, pkgs_of_year$Paquete))) == preselect_n
))

freqs <- arrange(as.data.frame(table(unlist(preselection))), desc(Freq), Var1) |>
  setNames(c("Paquetes", "Freq"))
filter(freqs, Freq > 1)
paste(sort(filter(freqs, Freq == 1)$Paquetes), collapse = ", ")
top_pkgs <- filter(pkgs_of_year, Paquete %in% unlist(preselection))
cat("Preselección:", nrow(top_pkgs), "paquetes de un total de", nrow(pkgs_of_year), ".")

### Evaluación final de los LLM.
final_prompt <- paste0(
  "De la lista de paquetes que te doy, ordena **TODOS** los paquetes de la lista ",
  "de la mejor calidad y utilidad a la peor. ",
  "Ordena los ", nrow(top_pkgs), " paquetes. ",
  "Asegúrate que en la lista que devuelvas, estén **TODOS** los paquetes. ",
  'Da tu respuesta en formato JSON (`["PAQ_1", ..., "PAQ_', nrow(top_pkgs), '"]`). ',
  "Esta es la lista de los paquetes que puedes seleccionar ",
  "(los paquetes que elijas, deben estar en esta lista (como campo `Package`):\n",
  "```json\n",
  toJSON(select(top_pkgs, Paquete, page_content, readme_content)),
  "\n```"
)

final_selection_replies <- ask_llms(final_prompt)
sapply(final_selection_replies, function(x) x$cost)
final_selection <- lapply(final_selection_replies, function(x) {
  intersect(fromJSON(gsub("\\].*", "]", gsub(".*\\[", "[", x$reply))), top_pkgs$Paquete)
})
# A veces los modelos dejan algunos paquetes sin evaluar, veamos si al menos ordenaron el 75%.
sapply(final_selection, length)
stopifnot(all(sapply(final_selection, length) >= nrow(top_pkgs) * .75))
# Chequear que todos hayan sido evaluados por al menos una IA.
stopifnot(all(top_pkgs$Paquete %in% unlist(final_selection)))
# Para cada modelo, agreguemos los paquetes que no rankearon.
final_selection <- lapply(final_selection, function(llm_selection) {
  c(llm_selection, sort(setdiff(top_pkgs$Paquete, llm_selection)))
})

### Consolidación de resultados.
all_scores <- map_dfr(names(final_selection), function(llm_name) {
  mutate(
    data.frame(llm = llm_name, package = unique(final_selection[[llm_name]])),
    position = row_number()
  )
}) |>
  add_count(package) |>
  filter(n == length(final_selection)) |>
  select(-n)

all_scores <- group_by(all_scores, package) |>
  summarise(position = mean(position)) |>
  arrange(position) |>
  left_join(pivot_wider(all_scores, names_from = llm, values_from = position), by = "package") |>
  left_join(downloads, by = "package") |>
  mutate(
    downloads = pmax(downloads, 0, na.rm = TRUE),
    daily_downloads_mean = pmax(daily_downloads_mean, 0, na.rm = TRUE)
  ) |>
  rename(Package = package, Position = position, Downloads = downloads, DDM = daily_downloads_mean)

# Gráfico para detectar si algún paquete con puntuación baja tiene muchas descargas.
pivot_longer(all_scores, cols = -Package) |>
  group_by(name) |>
  mutate(value = (value - min(value)) / (max(value) - min(value)), .groups = "drop") |>
  mutate(
    name = factor(name, levels = setdiff(colnames(all_scores), "Package")),
    Package = factor(Package, levels = rev(all_scores$Package)),
  ) |>
  ggplot(aes(x = name, y = Package, fill = value)) +
  geom_tile(color = "white", linewidth = 0.5) +
  scale_fill_gradient(low = "green", high = "red", name = "Value") +
  labs(x = "Value", y = "Package") +
  theme_minimal()

all_scores
arrange(all_scores, desc(daily_downloads_mean))
