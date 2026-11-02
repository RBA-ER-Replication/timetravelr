# pseudo-gertrude.R
# Hamish Sullivan, 2024
# Create functions which can spoof gertrude_timeseries for a given vintage.

# TODO:
# - Add more interpolation modes; interpolate even if more than min_vintage.
# - Deal with publication offsets in interpolation. Assume that the publication
# offset stays constant.
# Make sure that vintages all have a Vintage value and a publicationvintage value.

#' Retrieve timeseries from a long dataframe in the same format as rGertrude.
#' @param interpolate
#'  Cutoff of dates is done exclusively. For instance, if the Date + PublicationOffset
#'  is equal to the vintage date, then this observation will be dropped. This was
#'  set up so that the vintage dates can be SMP dates (which are publication dates
#'  for the SMP at the start of the month), and the publication dates might be end
#'  of month.
pseudo_gertrude_timeseries <- function(series_id, mnemonic,
                                       start_date, end_date,
                                       vintage_date, vintage_data, interpolate) {
  # Subset vintage data relating to requested series.
  vintages <- vintage_data |>
    dplyr::filter(GertrudeCode == series_id)

  # If the requested vintage date is unavailable,
  # take the earliest available vintage, remove
  # any data that was published after the requested
  # vintage date, and assume this is the requested vintage.
  min_vintage <- min(vintages$Vintage)
  if (as.Date(vintage_date) < min_vintage) {
    if (interpolate) {
      message(sprintf("%s: Requested vintage date %s is less than earliest
                             available vintage %s. Using the earliest available
                             vintage with any more recent dates cut off.",
                      series_id, vintage_date, min_vintage))

      vintages <- vintages |>
        dplyr::filter(Vintage == min_vintage) |>
        dplyr::filter(as.Date(lubridate::add_with_rollback(Date, months(PublicationOffset), preserve_hms=FALSE)) < as.Date(vintage_date)) |>
        dplyr::mutate(Vintage = as.Date(vintage_date))
    } else {
      message(sprintf("%s: Requested vintage date %s is less than earliest
                             available vintage %s. Interpolate is not TRUE.
                   Please set interpolate=TRUE if you wish for vintage to be
                   taken.",
                   series_id, vintage_date, min_vintage))
    }

  }

  # Convert vintage into GERTRUDE format.
  # Pivot into wide format.
  data <- vintages |>
    dplyr::filter(Vintage == vintage_date) |>
    dplyr::select(Date, GertrudeCode, Value) |>
    tidyr::pivot_wider(id_cols="Date", names_from="GertrudeCode",
                       values_from="Value")
  # Convert to zoo.
  zoo::zoo(x=data[,series_id], order.by = data$Date)
}

#' Pseudo gertrude mtimeseries
#' @param vintage does nothing. Is just a dummy argument for the vintage argument.
pseudo_gertrude_mtimeseries <- function(series_codes, mnemonic,
                                        start_date, end_date, vintage=NULL, tidy=F,
                                        vintage_date, vintage_data, interpolate) {
  fn <- purrr::partial(pseudo_gertrude_timeseries,
                       mnemonic=mnemonic,
                       start_date=start_date,
                       end_date=end_date,
                       vintage_date=vintage_date,
                       vintage_data=vintage_data,
                       interpolate=interpolate)
  out <- purrr::map(series_codes, fn) |>
    purrr::reduce(cbind)
  # Set the column names according to the named list
  if (!is.null(names(series_codes))) {
    colnames(out) <- names(series_codes)
  }

  # Tidy if applicable
  if (tidy) {
    out <- zoo::fortify.zoo(out, names = "date") |>
      tidyr::pivot_longer(!date, names_to="series", values_to="value")
  }

  out
}


#' Mask GERTRUDE functions with a pseudo gertrude session.
#' @details
#' Creates `gertrude_timeseries` and `mgertrude_timeseries` functions in the
#' global environment, backed by `vintage_data` rather than a live GERTRUDE
#' connection. `rGertrude` does not need to be installed for this to work,
#' since the functions are simply created rather than overridden. Call
#' [unmask_gertrude()] to undo this.
#' @export
mask_gertrude <- function(vintage_data, vintage_date, interpolate=TRUE) {
  message(sprintf("🕵 pseudo-GERTRUDE has replaced the GERTRUDE functions using vintage date: %s\n", vintage_date))

  if (!("PublicationOffset" %in% colnames(vintage_data)) & (interpolate=TRUE)) {
    stop("There needs to be a PublicationOffset column (timediff) in vintage_data
         for interpolate=TRUE to be used.")
  }

  gertrude_timeseries <<- purrr::partial(pseudo_gertrude_timeseries,
                                         vintage_date=vintage_date,
                                         vintage_data=vintage_data,
                                         interpolate=interpolate)
  mgertrude_timeseries <<- purrr::partial(pseudo_gertrude_mtimeseries,
                                          vintage_date=vintage_date,
                                          vintage_data=vintage_data,
                                          interpolate=interpolate)
}

#' Unmask GERTRUDE functions, resetting them to the original rGertrude ones.
#' @details
#' If `rGertrude` is installed, `gertrude_timeseries` and `mgertrude_timeseries`
#' are restored to the originals from that package. If `rGertrude` is not
#' installed (e.g. outside the Bank), there is nothing to restore, so the
#' pseudo-GERTRUDE functions created by [mask_gertrude()] are simply removed
#' instead.
#' @export
unmask_gertrude <- function() {
  if (requireNamespace("rGertrude", quietly = TRUE)) {
    message("🕵️ pseudo-GERTRUDE has replaced the GERTRUDE functions to their original state.")
    gertrude_timeseries <<- rGertrude::gertrude_timeseries
    mgertrude_timeseries <<- rGertrude::mgertrude_timeseries
  } else {
    message("🕵️ rGertrude is not installed; removing the pseudo-GERTRUDE functions instead of restoring the originals.")
    if (exists("gertrude_timeseries", envir = .GlobalEnv, inherits = FALSE)) {
      rm("gertrude_timeseries", envir = .GlobalEnv)
    }
    if (exists("mgertrude_timeseries", envir = .GlobalEnv, inherits = FALSE)) {
      rm("mgertrude_timeseries", envir = .GlobalEnv)
    }
  }
}

# vintages <- readRDS("../star-vintages-cleaned/star-vintages/draft_smp_vintages.R")
#
# mask_gertrude(vintages, "2006-02-01", TRUE)
#
# mgertrude_timeseries("A590698F")
