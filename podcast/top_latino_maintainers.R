box::use(
  dplyr[count, filter, mutate, row_number, select],
  ellmer[chat_claude, chat_google_gemini, chat_openai, params],
  jsonlite[fromJSON, toJSON],
  rvest[html_element, html_table, read_html],
  tidyr[fill]
)

### Obtener todos los maintainers de paquetes R.

maintainers <- read_html("https://cran.r-project.org/web/checks/check_summary_by_maintainer.html")
maintainers <- html_table(html_element(maintainers, "table"))
maintainers <- select(maintainers, Maintainer, Package, Version)
maintainers <- mutate(
  maintainers,
  Maintainer = ifelse(nchar(Maintainer) == 0, NA_character_, Maintainer)
) |> fill(Maintainer)
top_maintainers <- count(maintainers, Maintainer, sort = TRUE, name = "paquetes") |>
  mutate(position = row_number())

### Setear LLMs.
# Crear nuevas instancias de LLM para que tengamos sesiones de chat vacías.
ask_llms <- function(prompt) {
  llms <- list(
    # Claude no soporta la seed por el momento, igual dejemos el param por si lo hace en un futuro.
    claude = chat_claude(
      system_prompt, model = "claude-haiku-4-5-20251001", params = params(seed = 881918)
    ),
    gemini = chat_google_gemini(
      system_prompt, model = "gemini-2.5-flash", params = params(seed = 881918)
    ),
    openai = chat_openai(
      system_prompt, model = "gpt-5-mini", params = params(seed = 881918)
    )
  )
  lapply(llms, function(llm) {
    suppressWarnings(reply <- llm$chat(prompt))
    message("Spent: $", llm$get_cost())
    reply
  })
}

prompt <- paste0(
  "De la lista de nombres que te doy, debes devolverme la sublista filtrandom unicamente los que ",
  "creas que son latinos o nacidos en latinoamérica. ",
  'Da tu respuesta en formato JSON (`["NAME_1", ..., "NAME_N"]`).',
  "Esta es la lista de los nombres que puedes seleccionar ",
  "```json\n",
  toJSON(gsub(" <.*", "", unique(top_maintainers$Maintainer))[1:100]),
  "\n```"
)

latinamerican <- ask_llms(prompt)
latinamerican <- lapply(latinamerican, function(reply) {
  fromJSON(gsub("```.*", "", gsub(".*```json", "", reply)))
})

sort(table(unlist(latinamerican)))
# Giancarlo Vercellino      Pedro J. Aphalo        Pablo Sanchez         Ramiro Magno  Renzo Caceres Rossi
#                    2                    2                    3                    3                    3

(grep_query <- paste0(gsub(" ", ".", unique(unlist(latinamerican))), collapse = "|"))
filter(top_maintainers, grepl(grep_query, Maintainer))
# # A tibble: 7 × 3
# Maintainer                                               paquetes position
# <chr>                                                       <int>    <int>
# Pablo Sanchez <pablosama at outlook.es>                        26       26
# Renzo Caceres Rossi <arenzocaceresrossi at gmail.com>          26       27
# Giancarlo Vercellino <giancarlo.vercellino at gmail.com>       21       35
# Ramiro Magno <rmagno at pattern.institute>                     16       73
# Pedro J. Aphalo <pedro.aphalo at helsinki.fi>                  15       83
# Ramiro Magno <ramiro.magno at gmail.com>                        3     1795
# Ramiro Magno <ramiro.morgado at ascent.io>                      1    10239
