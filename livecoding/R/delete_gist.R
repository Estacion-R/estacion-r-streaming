#' Delete a gist
#'
#' Allows you to delete a gist.
#'
#' @param gist_id The unique identifier of the gist (character string).
#' @param github_pat Your GitHub Personal Access Token (PAT). It is recommended to set this as an
#'  environment variable (e.g., 'GITHUB_PAT').
#'
#' @return No return value. Called for its side effects.
#'
#' @importFrom httr add_headers DELETE
#'
#' @keywords internal
#'
delete_gist <- function(gist_id, github_pat = Sys.getenv("GITHUB_PAT")) {
  DELETE(
    paste0(gist_api_url, "/", gist_id),
    add_headers(Authorization = paste("token", github_pat))
  )
  invisible()
}
