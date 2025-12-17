#' Create a gist
#'
#' Allows you to add a new gist with one or more files.
#'
#' @param files A named list where names are the desired filenames and the values are the string
#'  content of those files.
#' @param description A brief, optional description of the gist (character string).
#' @param public A logical flag indicating whether the gist is public (`TRUE`) or secret (`FALSE`).
#'  Default is `TRUE`.
#' @param github_pat Your GitHub Personal Access Token (PAT). It is recommended to set this as an
#'  environment variable (e.g., 'GITHUB_PAT').
#'
#' @return A list containing the parsed JSON response from the GitHub API, which includes the Gist
#'  `id`, `url`, and `files` information.
#'
#' @importFrom httr add_headers content POST
#' @importFrom jsonlite toJSON
#'
#' @keywords internal
#'
create_gist <- function(files, description = NULL, public = TRUE,
                        github_pat = Sys.getenv("GITHUB_PAT")) {
  gist_files <- lapply(files, function(content) {
    list(content = paste(content, sep = "\n", collapse = "\n"))
  })
  response <- POST(
    gist_api_url,
    add_headers(Authorization = paste("token", github_pat)),
    body = toJSON(list(
      description = ifelse(is.null(description), "", description),
      public = public,
      files = gist_files
    ), auto_unbox = TRUE),
    encode = "raw"
  )
  if (response$status_code == 201) {
    content(response, as = "parsed")
  } else {
    stop(paste0("Failed to create Gist. HTTP Status: ", response$status_code, "."))
  }
}
