#' Join a Live Coding Session
#'
#' Connects your RStudio session to a broadcaster's session. This allows you to follow along with
#' code changes in real-time.
#'
#' @param owner The GitHub username of the broadcaster.
#' @param gist_id The ID of the gist being broadcasted. This is provided by the broadcaster.
#' @param refresh_rate Time in seconds between refreshes. Default is `5`.
#' @param stop_after Number of refreshes after which to automatically terminate. NULL for infinite
#'  loop. Default is `360` (30 minutes of running).
#'
#' @return No return value. Called for its side effects.
#'
#' @importFrom rstudioapi documentOpen executeCommand
#' @importFrom utils download.file
#'
#' @export
#'
join <- function(owner, gist_id, refresh_rate = 5, stop_after = 360) {
  tmp_file <- tempfile("livecoding_", fileext = ".R")
  writeLines(paste0(
    "livecoding:::join_script(",
    'owner = "', owner, '", ',
    'gist_id = "', gist_id, '", ',
    "refresh_rate = ", refresh_rate, ", ",
    "stop_after = ", stop_after,
    ")"
  ), tmp_file)
  jobRunScript(tmp_file, "Livecode Session")
}

#' Join a Live Coding Session Script
#'
#' Connects your RStudio session to a broadcaster's session. This allows you to follow along with
#' code changes in real-time.
#'
#' @param owner The GitHub username of the broadcaster.
#' @param gist_id The ID of the gist being broadcasted. This is provided by the broadcaster.
#' @param refresh_rate Time in seconds between refreshes. Default is `5`.
#' @param stop_after Number of refreshes after which to automatically terminate. NULL for infinite
#'  loop. Default is `360` (30 minutes of running).
#'
#' @return No return value. Called for its side effects.
#'
#' @importFrom rstudioapi documentOpen executeCommand
#' @importFrom utils download.file
#'
join_script <- function(owner, gist_id, refresh_rate = 5, stop_after = 360) {
  tmp_file <- tempfile("livecoding_", fileext = ".R")
  message(paste0("Live Coding temporary file: ", tmp_file))
  file_url <- paste0("https://gist.githubusercontent.com/", owner, "/", gist_id, "/raw/")
  refresh_count <- 0
  while (refresh_count < stop_after) {
    refresh_count <- refresh_count + 1
    # Add a timestamp as a query parameter to bust the cache.
    download.file(paste0(file_url, "?t=", as.numeric(Sys.time())), tmp_file, quiet = TRUE)
    Sys.sleep(refresh_rate)
    # Move the focus to the console, so the source pane updates.
    executeCommand("activateConsole")
    documentOpen(tmp_file)
  }
  invisible()
}
