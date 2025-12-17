#' Live Code
#'
#' Continuously monitors the active RStudio source file and pushes changes to a GitHub Gist for
#' live broadcasting.
#'
#' @param refresh_rate Time in seconds between refreshes. Default is `5`.
#' @param stop_after Number of refreshes after which to automatically terminate. NULL for infinite
#'  loop. Default is `360` (30 minutes of running).
#' @param clean_up Whether to delete the gist when the livecoding ends.
#'
#' @importFrom rstudioapi getSourceEditorContext jobRunScript
#'
#' @export
#'
livecode <- function(refresh_rate = 5, stop_after = 360, clean_up = TRUE) {
  tmp_file <- tempfile("livecoding_", fileext = ".R")
  context <- getSourceEditorContext()
  writeLines(paste0(
    "livecoding:::livecode_script(",
    'context_id = "', context$id, '", ',
    "refresh_rate = ", refresh_rate, ", ",
    "stop_after = ", stop_after, ", ",
    "clean_up = ", clean_up,
    ")"
  ), tmp_file)
  jobRunScript(tmp_file, paste0("Livecode Session - ", basename(context$path)))
}

#' Live Code Script
#'
#' Continuously monitors the active RStudio source file and pushes changes to a GitHub Gist for
#' live broadcasting.
#'
#' @param context_id The ID of an rstudioapi's `document_context` to broadcast. If `NULL`, it will
#'  load the currently open file. Default is `NULL`.
#' @param refresh_rate Time in seconds between refreshes. Default is `5`.
#' @param stop_after Number of refreshes after which to automatically terminate. NULL for infinite
#'  loop. Default is `360` (30 minutes of running).
#' @param clean_up Whether to delete the gist when the livecoding ends.
#'
#' @importFrom rstudioapi getSourceEditorContext
#' @importFrom stats setNames
#'
livecode_script <- function(context_id = NULL, refresh_rate = 5, stop_after = 360,
                            clean_up = TRUE) {
  pushed <- getSourceEditorContext(context_id)
  gist_description <- paste0("Live Coding: ", basename(pushed$path), " - ", Sys.time())
  gist <- create_gist(setNames(list(pushed$contents), basename(pushed$path)), gist_description)
  if (clean_up) on.exit(delete_gist(gist$id))
  message(paste0('Run `livecoding::join("', gist$owner$login, '", "', gist$id, '")`.'))
  refresh_count <- 0
  while (refresh_count < stop_after) {
    refresh_count <- refresh_count + 1
    Sys.sleep(refresh_rate)
    new_content <- getSourceEditorContext()
    if (new_content$path != pushed$path) {
      # If the caster changed the open file, skip updates.
      next
    }
    if (isTRUE(all.equal(new_content$contents, pushed$contents))) {
      # Nothing changed, don't push content.
      next
    }
    pushed <- new_content
    message(paste0("\u2714 Last Update: ", Sys.time()))
    update_gist(gist$id, setNames(list(pushed$contents), basename(pushed$path)), gist_description)
  }
  "Reached maximum number of refreshes"
}
