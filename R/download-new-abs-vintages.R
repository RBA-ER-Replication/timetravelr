#' Download abs vintages post 2019 using readabs.
#' @export
download_abs_vintages <- function(vintage_dates, cat_no=NULL, tables=NULL,  path, series_id=NULL) {
  onError <- function(e, vintage_date) {
    print(sprintf("Error in vintage date %s: %s", vintage_date, e))
    data.frame()
  }

  func <- function(vintage_date) {
    tryCatch({
      readabs::read_abs(release_date=vintage_date, cat_no=cat_no, tables=tables, path=sprintf("%s/%s", path, as.character(vintage_date)), series_id=series_id)
    }, error=purrr::partial(onError, vintage_date=vintage_date))

  }
  purrr::map(vintage_dates, func, .progress=TRUE) |>
    dplyr::bind_rows()
}

#' Manual function for downloading of ABS CPI vintages with a specific url format,
#' that doesn't seem to be supported by readabs.
#' @export
download_recent_cpi_helper <- function(date, filename, cat_no, savedir) {
  year <- lubridate::year(date)
  month <- format(date, "%b") |> as.character() |> tolower()
  url <- sprintf("https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/consumer-price-index-australia/%s-quarter-%s/%s", month, year, filename)
  save_path <- sprintf("%s/%s/%s/%s", savedir, date, cat_no, filename)
  download.file(url, save_path, mode = "wb")
}
