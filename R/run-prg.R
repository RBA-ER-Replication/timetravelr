#' Switch working directory to dir_ and run program given by prg_file
#' @param prg_file name of the .prg file that is to be run.
#' @param run_dir directory within which the file is located.
#' @export
run_prg <- function(prg_file, run_dir) {
  cat(sprintf("Running: %s in %s\n", prg_file, run_dir))
  cur_dir <- getwd()
  tryCatch({
    setwd(run_dir)
    prog <- readr::read_tsv(prg_file,
                            col_names = FALSE,
                            show_col_types = FALSE)[[1]] |> as.vector()
    EviewsR::exec_commands(prog)
    setwd(cur_dir)
  }, error=function(e) {
    print(e)
    setwd(cur_dir)
  })
}

run_prg_for_vintage <- function(prg_files, output_dir, vintage_date) {
  run_dir <- sprintf("%s/%s", output_dir, vintage_date)
  purrr::map(prg_files, purrr::partial(run_prg, run_dir=run_dir))
}

#' Given a list of vintage dates and .prg files to run, run those .prg files.
#' @export
run_prgs_for_vintages <- function(vintage_dates, prg_files, output_dir,
                                  eviewsPath="C:/Program Files/EViews 13/Eviews13.exe") {
  EviewsR::set_eviews_path(eviewsPath)
  purrr::map(vintage_dates, purrr::partial(run_prg_for_vintage,
                                           prg_files=prg_files,
                                           output_dir=output_dir))
}
