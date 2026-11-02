read_absfile <- function(vintage_date, cat_no, download_dir) {
  # if (vintage_date == as.Date("2019-09-01")) {
  #     browser()
  # }
  path <- sprintf("%s/%s", download_dir, vintage_date)
  read_absfile_ <- function() {
    readabs::read_abs_local(cat_no=cat_no, path = path) |>
      dplyr::mutate(vintage=vintage_date)
  }

  onError <- function(e) {
    print(sprintf("Unable to read %s. Error: %s", path, e))
    NULL
  }

  tryCatch(read_absfile_(), error=onError)
}

#' Assumes the files are downloaded into a file structure equivalent to
#' using the default parameters for download_absfiles.
#' @param vintage_dates list of vintage dates to download.
#' @param cat_no ABS catalogue number in string format.
#' @param download_dir directory to read files from within.
#' @export
read_absfiles <- function(vintage_dates, cat_no, download_dir) {
  purrr::map(vintage_dates, purrr::partial(read_absfile, cat_no=cat_no, download_dir=download_dir)) |>
    dplyr::bind_rows()
}
