
#' Pulls the release date for a given URL. Loads the page and retrieves the
#' DC.Date.issued parameter.
#' It is probably also possible to retrieve the release date from the visual
#' part of the page as well, though this seems to work and is elegant.
#' @param urls List of URLs, each for a particular ABS release.
pull_release_dates <- function(urls, verbose=F) {
    pull_release_date <- function(url) {
        if (verbose) {
            message(sprintf("Pulling %s", url))
        }
        page <- rvest::read_html(url)
        date_ <- page |>
            rvest::html_node("meta[name='DC.Date.issued']") |>
            rvest::html_attr("content")
        if (is.na(date_)) {
            # Handle more recent ABS publications.
            date_ <- page |>
                rvest::html_node("meta[name='dcterms.issued']") |>
                rvest::html_attr("content") |>
                stringr::str_split_i(" ", 2) |>
                as.Date(date_, format="%d/%m/%Y") |> # Take the date and remove the day of week and time.
                as.character()
            }
        date_
    }
    purrr::map(urls, pull_release_date, .progress=T) |>
        as.character()
}


# Implementation 1 - Simple - Retrieves pre-2019 dates only
#' Get ABS release date for a given vintage date and cat no.
#' Currently only supports Pre-2019 vintages.
#' Use get_abs_release_dates if you want the full set of vintages to be available.
get_abs_publication_dates.simple <- function(vintage_date, cat_no="6401.0") {
   url <- get_url(vintage_date, cat_no, annual=F)
    date_ <- pull_release_dates(url)
    data.frame(abs_cat_no=cat_no, vintage_date=vintage_date, release_day=date_)
}

# TODO: Post-2019 dates are supported by xml_urls <- readabs:::form_abs_tsd_url(cat_no = "6202.0") and readabs:::get_abs_xml_metadata(xml_urls)
# The rest of tardis could aslo support this. 

# Implementation 2 --------------------------------------------------------

#' Get all ABS release dates for a release page.
#' This function was implemented at request of Martin McCarthy. It could be useful for
#' fixing some of the teething issues with the different release URL formats in future.
#' But currently, it is not used anywhere else within timetravelr.
#' The function could also be integrated in future to retrieve the release_url automatically.
#' @param release_url Page containing links to all past ABS releases for a
#' given page.
#' @param vintage_dates List of vintage dates to filter to before querying all
#' the publication dates. Narrowing the set of vintage dates will improve
#' speed.
#' @export
get_abs_publication_dates <- function(release_url="https://www.abs.gov.au/statistics/labour/employment-and-unemployment/labour-force-australia",
                                  vintage_dates=NULL,
                                  verbose=F) {
    nodes <- rvest::read_html(release_url) |>
        rvest::html_nodes("div.views-field a")

    link_data <- tibble::tibble(
        release_name = rvest::html_text(nodes),
        href = rvest::html_attr(nodes, "href")) |>
        dplyr::mutate(
            full_url = dplyr::case_when(stringr::str_starts(href, "https\\:\\/\\/") ~ href,
                                        .default=paste0("https://www.abs.gov.au", href)) |>
                utils::URLencode(),
            vintage_date = lubridate::parse_date_time(release_name, orders = "B Y", tz = "UTC", quiet = T),
            vintage_date = format(vintage_date, "%Y-%m-%d")
        )
    if (!is.null(vintage_dates)) {
        link_data <- link_data |>
            dplyr::filter(vintage_date %in% vintage_dates)
    }
    link_data |>
        dplyr::mutate(publication_date = pull_release_dates(full_url, verbose=verbose))
}




