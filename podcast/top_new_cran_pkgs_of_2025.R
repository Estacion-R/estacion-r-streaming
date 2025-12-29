box::use(
  cranlogs[cran_downloads],
  dplyr[
    add_count, arrange, desc, distinct, filter, group_by, left_join, mutate, row_number, rowwise,
    select, summarise
  ],
  ellmer[chat_claude, chat_google_gemini, chat_openai, params],
  ggplot2[aes, geom_bar, geom_tile, ggplot, scale_fill_gradient],
  jsonlite[fromJSON, toJSON],
  lubridate[as_date, floor_date],
  purrr[map_dfr],
  rvest[html_element, html_elements, html_table, html_text, read_html],
  tidyr[pivot_longer, pivot_wider]
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
  ggplot(aes(x = ReleaseMonth)) +
  geom_bar()
pkgs_of_year <- filter(packages, Package %in% cranberries$Package)
cat("Se encontraron", nrow(pkgs_of_year), "paquetes nuevos para 2025.")

### Obtener número de descargas por paquete.
downloads <- map_dfr(
  split(pkgs_of_year$Package, ceiling(seq_along(pkgs_of_year$Package) / 100)),
  function(pkgs) cran_downloads(pkgs, from = "2025-01-01", to = "2025-12-31")
) |>
  filter(count > 0) |>
  group_by(package) |>
  summarise(downloads = sum(count), daily_downloads_mean = round(mean(count))) |>
  arrange(desc(downloads))
downloads

### Obtener el top-10 de cada mes.
dates <- format(
  seq.Date(as_date("2025-01-01"), as_date("2025-12-01"), by = "month"),
  "%Y%m"
)
top_pkgs <- map_dfr(dates, function(date) {
  page <- read_html(paste0("podcast/top_new_cran_pkgs_", date, ".html"))
  html_element(page, "#resultados-finales") |>
    html_table() |>
    mutate(Fecha = date)
})

### Leer la página de cada paquete y su README.
read_page <- function(url) {
  tryCatch(html_text(read_html(url)), error = function(e) NA_character_)
}

top_pkgs <- mutate(
  top_pkgs,
  url = paste0("https://cran.r-project.org/web/packages/", Paquete, "/index.html"),
  readme_url = paste0(
    "https://cran.r-project.org/web/packages/", Paquete, "/readme/README.html"
  )
)
system.time({
  top_pkgs <- mutate(
    rowwise(top_pkgs),
    page_content = read_page(url), readme_content = read_page(readme_url)
  )
})

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
  )

# Gráfico para detectar si algún paquete con puntuación baja tiene muchas descargas.
pivot_longer(all_scores, cols = -package) |>
  group_by(name) |>
  mutate(value = (value - min(value)) / (max(value) - min(value)), .groups = "drop") |>
  mutate(
    name = factor(name, levels = setdiff(colnames(all_scores), "package")),
    package = factor(package, levels = rev(all_scores$package)),
  ) |>
  ggplot(aes(x = name, y = package, fill = value)) +
  geom_tile(color = "white", linewidth = 0.5) +
  scale_fill_gradient(low = "green", high = "red", name = "Value")

all_scores
arrange(all_scores, desc(daily_downloads_mean))
