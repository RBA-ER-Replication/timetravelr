# data-raw/example-vintage-viewer.R
# Hamish Sullivan, 2025
#
# Launches the timetravelr Vintage Viewer using publicly available ABS National
# Accounts data (Unit Labour Costs, cat no. 5206.0), rather than internal RBA
# data. Intended for generating example screenshots/animations for the
# package vignette (see vignettes/timetravelr.Rmd).
#
# Requires ABS vintage files already downloaded into a directory structured
# as <download_dir>/<vintage_date>/<cat_no>/*.xls[x] (see ?read_absfiles).
# By default this points at the files already downloaded in the
# star-vintages repository; update download_dir if running elsewhere, or use
# ABS.find_files()/ABS.download_files() to download fresh copies.

library(timetravelr)

# 1. Configuration ---------------------------------------------------------
download_dir <- "C:/Dev/star-vintages/input_data/ABS"
cat_no <- "5206.0"
vintage_dates <- seq(as.Date("2006-03-01"), as.Date("2024-06-01"), by = "quarter")

# A small set of related, non-sensitive Unit Labour Cost index series
# (seasonally adjusted, whole economy and non-farm, nominal and real).
series_names <- c(
  A2433068T = "Unit labour costs - Nominal",
  A2433071F = "Unit labour costs - Real",
  A2433074L = "Unit labour costs - Nominal (non-farm)",
  A2433077V = "Unit labour costs - Real (non-farm)"
)

# 2. Load and reshape vintages into vintage_viewer's expected format -------
# (columns: Name, Vintage, Date, Value)
ulc_vintages <- read_absfiles(vintage_dates, cat_no = cat_no, download_dir = download_dir)

example_vintages <- ulc_vintages |>
  dplyr::filter(series_id %in% names(series_names),
                series_type == "Seasonally Adjusted") |>
  dplyr::mutate(Name = unname(series_names[series_id])) |>
  dplyr::select(Name, Vintage = vintage, Date = date, Value = value) |>
  dplyr::filter(!is.na(Value))

# 3. Launch the viewer ------------------------------------------------------
# - "Multi-vintage" tab: select a single Name to see it across vintages.
# - "Multi-series" tab: select a single vintage, with multiple Names, to
#   compare series.
# - "Dynamic Charts" tab: generates a .gif animation across vintages.
vintage_viewer(example_vintages)
