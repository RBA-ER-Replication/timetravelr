# Read metadata
vgertrude.clean_cols <- function(columns, current_vintage) {
  clean_col <- function(col) {
    if (col == "Current") {
      col <- current_vintage
    } else {
      col <- stringr::str_replace(col, "Previous: ", "")
    }
    col
  }
  purrr::map(columns, clean_col) |>
    purrr::reduce(c)
}

vgertrude.read_metadata <- function(fname, current_vintage) {
  data <- readxl::read_excel(fname, col_names=FALSE, .name_repair="unique_quiet")
  export_time <- data[1,1]
  metadata <- t(data[2:12, 2:ncol(data)])
  colnames(metadata) <- unlist(unname(as.vector(data[2:12, 1])))
  rownames(metadata) <- NULL
  metadata <- as.data.frame(metadata) |>
    dplyr::select(!`Vintage Type`) |>
    unique()
  metadata$`Download Timestamp` <- export_time
  # Assert that there arent differences in the metadata across different vintages.
  if (nrow(metadata) > 1) {
    stop(sprintf("The metadata for %s is different depending on the vintage.
                 Are you sure this file has been directly downloaded from GERTRUDE?"))
  }

  metadata
}

load_gert_vintages <- function(file, current_vintage, assert_series_id=NULL) {
  raw <- readxl::read_excel(file, skip=11) |>
    dplyr::rename_with(purrr::partial(vgertrude.clean_cols, current_vintage=current_vintage)) |>
    dplyr::rename(Date = `Vintage Type`)

  if(!is.null(assert_series_id)) {
    if(any(raw[1,2:ncol(raw)] != assert_series_id)) {
      stop(sprintf("At least one of the vintages in %s is not %s", file, assert_series_id))
    }
  }
  raw[2:nrow(raw), ] |>
    dplyr::mutate(Date = as.Date(as.numeric(Date), origin="1899-12-30")) |>
    dplyr::mutate(dplyr::across(!Date, ~ as.numeric(.x)))

}


#' Given a .xlsx file containing vintages as downloaded from the GERTRUDE web
#' service, read in the vintages.
#' @param series_id GERTRUDE series code.
#' @param assume_current_vintage The file does not specify the date for the
#' current vintage. Please put in the date for the current vintage here.
#' @param vintage_dir directory within which the vintages file is located.
#' @param vintage_filename File name of the .xlsx file. By default, is equal to
#' 'series_id'_Multiple_Vintages.xlsx.
#' @param skip_metadata if TRUE, skip loading in of metadata. Will speed things
#' up and remove the restriction that all vintages have to have the identical
#' metadata.
#' @param verbose_metadata if TRUE, includes all metadata fields.
#' @export
load_gert_vintages_long <- function(series_id, assume_current_vintage,
                                    vintage_dir,
                                    vintage_filename=sprintf("%s_Multiple_Vintages.xlsx", series_id),
                                    skip_metadata=FALSE,
                                    verbose_metadata=FALSE) {
  vintage_file <- sprintf("%s/%s", vintage_dir, vintage_filename)
  if (!file.exists(vintage_file)) {
    stop(sprintf("The file containing vintage data %s does not exist.", vintage_file))
  }
  data <- load_gert_vintages(vintage_file, assume_current_vintage, assert_series_id = series_id) |>
    tidyr::pivot_longer(!Date, names_to="Vintage", values_to="Value") |>
    dplyr::mutate(GertrudeCode=series_id)

  if (!skip_metadata) {
    metadata <- vgertrude.read_metadata(vintage_file, current_vintage)
    data <- dplyr::bind_cols(data, metadata)
  }

  if (!verbose_metadata) {
    data <- dplyr::select(data, Date, Vintage, Value, GertrudeCode,
                          `Series Name`)
  }

  data
}
