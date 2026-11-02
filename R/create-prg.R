#' Load a .prg template from file, and replace values with values in params.
#' Save to save_path if save_path is not NULL.
#' @param template_path path where the template exists in.
#' @param params list, mapping string(s) to match with the value that is to be
#' replaced.
#' @param save_path path where the file is to be saved to.
#'
#' @export
create_prg <- function(template_path, params, save_path=NULL) {
  prog <- readr::read_tsv(template_path,
                          col_names = FALSE,
                          show_col_types = FALSE)[[1]] |> as.vector()
  for (const in names(params)) {
    prog <- stringr::str_replace_all(prog, const, params[[const]])
  }

  if(!is.null(save_path)) {
    dir_ <- dirname(save_path)
    if (!dir.exists(dir_)) {
      dir.create(dir_)
    }
    write(paste0(prog, collapse="\n"), save_path)
  }
  prog
}

#' Copy a file from one directory to another, keeping the filename unchanged.
#' @param file_ the name of the file.
#' @param start_dir directory where the file is to be copied from.
#' @param end_dir directory where the file is to be copied to.
#'
copy_file <- function(file_, start_dir, end_dir, verbose=FALSE) {
  # Create end directory if does not exist.
  dir_ <- dirname(end_dir)
  if (!dir.exists(end_dir)) {
    dir.create(end_dir)
  }

  status <- file.copy(sprintf("%s/%s", start_dir, file_),
            overwrite=TRUE,
            sprintf("%s/%s", end_dir, file_))
  if (verbose) {
    if (status) {
      cat(sprintf("Copied file %s from %s to %s.\n", file_, start_dir, end_dir))
    } else {
      cat(sprintf("Failed to copy file %s from %s to %s.\n", file_, start_dir, end_dir))
    }
  }
  status
}


create_scripts_for_vintage <- function(vintage_date, template_dir, output_dir,
                         copy_files, edit_prgs, params_generator, verbose=FALSE) {
  save_dir <- sprintf("%s/%s", output_dir, vintage_date)
  # Copy over 'copy files' from the template directory to the save directory.
  copy_fn <- purrr::partial(copy_file, start_dir=template_dir, end_dir=save_dir,
                            verbose=verbose)
  purrr::map(copy_files, copy_fn)
  # For each edit script, generate the relevant parameters, edit the script,
  # and save to file.
  edit_script <- function(file_) {
    template_path <- sprintf("%s/%s", template_dir, file_)
    save_path <- sprintf("%s/%s", save_dir, file_)
    # Get parameters for given vintage date and file name
    params <- params_generator(vintage_date, file_)
    create_prg(template_path, params, save_path)
    if (verbose) {
      cat(sprintf("Edited %s template from %s and saved to %s.\n", file_, template_path, save_path))
    }
  }
  purrr::map(edit_prgs, edit_script)
}

#' Given a directory containing script templates, a directory to save output to,
#' a list of vintage dates, a list of files to copy, a list of files to edit,
#' and a function which generates the parameters to insert into those files,
#' write all the necessary scripts to the output directory.
#' @param vintage_dates a list of vintage dates to create files for.
#' @param template_dir Directory where the template files are stored.
#' @param output_dir Directory where the files will be written to. Each vintage
#' will get its own subdirectory.
#' @param copy_files list of file names which are to be directly copied from
#' `template_dir` to `save_dir`, without editing.
#' @param edit_prgs list of (.prg or tsv) file names within `template_dir` which
#' are to be 1. opened, 2. constants replaced with values as per `params`, and
#' 3. saved to the `save_dir`.
#' @param params_generator a function which takes in two arguments: the vintage date
#' and the file name. The function should return a list of parameters to be inserted into
#' the corresponding file. See details for more information.
#' @param verbose If TRUE, will print each file that is copied
#' @details
#' `params_generator` should be a function which takes in the vintage_date and
#' the name of the file being edited.
#' It should return a list mapping string(s) to match with the value that is to be
#' replaced. Any occurrences of 'name' will be replaced with 'value' using
#' `stringr::str_replace_all`.
#' @export
create_scripts_for_vintages <- function(vintage_dates, template_dir, output_dir,
                          copy_files, edit_prgs, params_generator, verbose=FALSE) {
  fn <- purrr::partial(create_scripts_for_vintage,
                       template_dir=template_dir,
                       output_dir=output_dir,
                       copy_files=copy_files,
                       edit_prgs=edit_prgs,
                       params_generator=params_generator,
                       verbose=verbose)
  purrr::map(vintage_dates, fn)
}

#'
#' #' Given a directory containing script templates, a list of scripts to copy and
#' #' a list of scripts to edit (and parameters to edit those scripts with),
#' #' write all the necessary scripts to the output directory.
#' #' @param template_dir Directory where the template files are stored.
#' #' @param save_dir Directory where the files will be written to.
#' #' @param copy_files list of file names which are to be directly copied from
#' #' `template_dir` to `save_dir`, without editing.
#' #' @param edit_prgs list of (.prg or tsv) file names within `template_dir` which
#' #' are to be 1. opened, 2. constants replaced with values as per `params`, and
#' #' 3. saved to the `save_dir`.
#' #' @param edit_params Either a list or a function which returns a list. See details.
#' #' @param verbose If TRUE, will print each file that is copied
#' #' @details
#' #' `edit_params` can be a list, mapping string(s) to match with the value that is to be
#' #' replaced. Any occurrences of [name] will be replaced with [value] using
#' #' `stringr::str_replace_all`. Alternatively, provide a function, which given a
#' #' particular `save_dir`, returns a list with the relevant parameters. This is
#' #' useful if your paramters need to vary with the
#' #'
#' #' @export
#' setup_scripts.legacy <- function(template_dir, save_dir, copy_files, edit_prgs, edit_params,
#'                           verbose=FALSE) {
#'   # Copy over 'copy files' from the template directory to the save directory.
#'   copy_fn <- purrr::partial(copy_file, start_dir=template_dir, end_dir=save_dir,
#'                             verbose=verbose)
#'   purrr::map(copy_files, copy_fn)
#'
#'   # Edit templates which need editing before saving to the save directory.
#'   edit_fn <- function(file_) {
#'     template_path <- sprintf("%s/%s", template_dir, file_)
#'     save_path <- sprintf("%s/%s", save_dir, file_)
#'     if (is.function(edit_params)) {
#'       params <- edit_params(save_dir)
#'     } else {
#'       params <- edit_params
#'     }
#'     create_prg(template_path, params, save_path)
#'     if (verbose) {
#'       cat(sprintf("Edited %s template from %s and saved to %s.\n", file_, template_path, save_path))
#'     }
#'
#'   }
#'   purrr::map(edit_prgs, edit_fn)
#' }
