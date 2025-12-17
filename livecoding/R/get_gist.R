#' Get a gist
#'
#' Allows you to get a gist.
#'
#' @param gist_id The unique identifier of the gist (character string).
#'
#' @return A list containing the parsed JSON response from the GitHub API, which includes the Gist
#'  `id`, `url`, and `files` information.
#'
#' @importFrom httr content GET
#'
#' @keywords internal
#'
get_gist <- function(gist_id) {
  response <- GET(paste0(gist_api_url, "/", gist_id))
  if (response$status_code == 200) {
    content(response, as = "parsed")
  } else {
    stop(paste0("Failed to get Gist. HTTP Status: ", response$status_code, "."))
  }
}
