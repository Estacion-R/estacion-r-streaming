box::use(
  cranlogs[cran_downloads],
  dplyr[
    add_count, arrange, desc, filter, group_by, left_join, mutate, row_number, rowwise, select,
    summarise
  ],
  ellmer[chat_claude, chat_google_gemini, chat_openai, params],
  ggplot2[aes, geom_tile, ggplot, scale_fill_gradient],
  jsonlite[fromJSON, toJSON],
  lubridate[`%m-%`, as_date, ceiling_date, floor_date, month, today, wday, year],
  purrr[map_dfr],
  rvest[html_elements, html_table, html_text, read_html],
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

### Obtener paquetes publicados el mes pasado.
(last_month <- floor_date(`%m-%`(today(), months(1)), "month"))
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
cranberries <- paste0("https://dirk.eddelbuettel.com/cranberries/", format(last_month, "%Y/%m")) |>
  read_html() |>
  html_elements(".package") |>
  html_elements("b") |>
  html_text()
new_pkgs <- gsub(
  " .*", "", gsub("^New package ", "", cranberries[grepl("^New package ", cranberries)])
)
pkgs_of_month <- filter(packages, Package %in% new_pkgs)
cat("Se encontraron", nrow(pkgs_of_month), "paquetes nuevos para", format(last_month, "%B"), ".")

### Obtener número de descargas por paquete.
downloads <- cran_downloads(
  pkgs_of_month$Package,
  from = as.character(last_month), to = as.character(ceiling_date(last_month, "month") - 1)
) |>
  filter(count > 0) |>
  group_by(package) |>
  summarise(downloads = sum(count), daily_downloads_mean = round(mean(count))) |>
  arrange(desc(downloads))
downloads

### Pedir a los LLM que preseleccionen los mejores paquetes por nombre y título.
# Esto se debe a que si no preseleccionamos, entonces tenemos alrededor de 250 paquetes para leer
# páginas y enviar a LLM (podríamos hacerlo con el total de todos modos).
preselect_n <- 25
prompt <- paste0(
  "De la lista de paquetes que te doy, debes hacer un pre-filtrado de ", preselect_n, " paquetes. ",
  "Devuelveme solo el nombre de los paquetes de los cuales te gustaria obtener mas informacion. ",
  'Da tu respuesta en formato JSON (`["PAQ_1", ..., "PAQ_N"]`).',
  "Esta es la lista de los paquetes que puedes seleccionar ",
  "(los paquetes que elijas, deben estar en esta lista (como campo `Package`):\n",
  "```json\n",
  toJSON(select(pkgs_of_month, Package, Title)),
  "\n```"
)

preselection_replies <- ask_llms(prompt)
sapply(preselection_replies, function(x) x$cost)
preselection <- lapply(preselection_replies, function(x) {
  unique(fromJSON(gsub("\\].*", "]", gsub(".*\\[", "[", x$reply))))
})
stopifnot(all(sapply(preselection, length) == preselect_n))

arrange(as.data.frame(table(unlist(preselection))), desc(Freq), Var1) |>
  setNames(c("Paquetes", "Frecuencia")) |>
  head(n = 20)
top_pkgs <- filter(pkgs_of_month, Package %in% unlist(preselection))
cat("Preselección:", nrow(top_pkgs), "paquetes de un total de", nrow(pkgs_of_month), ".")

### Leer la página de cada paquete y su README.
read_page <- function(url) {
  tryCatch(html_text(read_html(url)), error = function(e) NA_character_)
}
system.time({
  top_pkgs <- mutate(
    rowwise(top_pkgs),
    page_content = read_page(url), readme_content = read_page(readme_url)
  )
})

### Evaluación final de los LLM.
final_prompt <- paste0(
  "De la lista de paquetes que te doy, ordena **todos** los paquetes de la lista ",
  "de la mejor calidad y utilidad a la peor. ",
  "Ordena los ", nrow(top_pkgs), " paquetes. ",
  'Da tu respuesta en formato JSON (`["PAQ_1", ..., "PAQ_', nrow(top_pkgs), '"]`).',
  "Esta es la lista de los paquetes que puedes seleccionar ",
  "(los paquetes que elijas, deben estar en esta lista (como campo `Package`):\n",
  "```json\n",
  toJSON(select(top_pkgs, Package, Title, page_content, readme_content)),
  "\n```"
)

final_selection_replies <- ask_llms(final_prompt)
sapply(final_selection_replies, function(x) x$cost)
final_selection <- lapply(final_selection_replies, function(x) {
  unique(fromJSON(gsub("\\].*", "]", gsub(".*\\[", "[", x$reply))))
})
stopifnot(all(sapply(final_selection, length) == nrow(top_pkgs)))

### Consolidación de resultados.
all_scores <- map_dfr(names(final_selection), function(llm_name) {
  mutate(data.frame(llm = llm_name, package = unique(final_selection[[llm_name]])), position = row_number())
}) |>
  add_count(package) |>
  filter(n == length(final_selection)) |>
  select(-n)

all_scores <- group_by(all_scores, package) |>
  summarise(position = mean(position)) |>
  arrange(position) |>
  left_join(pivot_wider(all_scores, names_from = llm, values_from = position), by = "package") |>
  left_join(downloads, by = "package")

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

quarto::quarto_render(
  "podcast/top_new_cran_pkgs.qmd",
  output_file = paste0("top_new_cran_pkgs_", format(last_month, "%Y%m"), ".html"),
  execute_params = list(
    last_month = as.character(last_month),
    pkgs_of_month = pkgs_of_month,
    preselection_replies = preselection_replies,
    top_pkgs = top_pkgs$Package,
    final_selection_replies = final_selection_replies,
    all_scores = all_scores
  )
)
