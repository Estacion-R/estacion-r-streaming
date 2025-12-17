#' Update a gist
#'
#' Allows you to update a gist's description and to update, delete, or rename gist files.
#'
#' @param gist_id The unique identifier of the gist (character string).
#' @param files A named list for file changes. Keys must match current filenames.
#'  - Update content: Value is a string of the new content.
#'  - Rename file: Value is a list, e.g., `list(filename = "new_name.R")`.
#'  - Delete file: Value is `NULL`.
#' @param description The new description of the gist (character string). Can be `NULL`.
#' @param github_pat Your GitHub Personal Access Token (PAT). It is recommended to set this as an
#'  environment variable (e.g., 'GITHUB_PAT').
#'
#' @return A list containing the parsed JSON response from the GitHub API, which includes the Gist
#'  `id`, `url`, and `files` information.
#'
#' @importFrom httr add_headers content PATCH
#' @importFrom jsonlite toJSON
#'
#' @keywords internal
#'
update_gist <- function(gist_id, files, description = NULL, github_pat = Sys.getenv("GITHUB_PAT")) {
  gist_files <- lapply(files, function(file_change) {
    if (is.null(file_change)) {
      # Deletion: Return NULL for the key's value in the API JSON
      NULL
    } else if (is.list(file_change) && !is.null(file_change$filename)) {
      # Renaming: Return the list (e.g., list(filename = "new.R"))
      file_change
    } else {
      # Content Update: Return a list with the 'content' key
      list(content = paste(file_change, sep = "\n", collapse = "\n"))
    }
  })
  response <- PATCH(
    paste0(gist_api_url, "/", gist_id),
    add_headers(Authorization = paste("token", github_pat)),
    body = toJSON(list(
      description = ifelse(is.null(description), "", description),
      files = gist_files
    ), auto_unbox = TRUE),
    encode = "raw"
  )
  if (response$status_code == 200) {
    content(response, as = "parsed")
  } else {
    stop(paste0("Failed to update Gist. HTTP Status: ", response$status_code, "."))
  }
}
