detect_wrong_file <- function(raw_df, data_name) {
  if (is.null(raw_df)) {
    return(NULL)
  }
  cols <- names(raw_df)
  if (any(file_signatures[[data_name]] %in% cols)) {
    return(NULL)
  }
  matches <- sapply(file_signatures, function(sigs) sum(sigs %in% cols))
  best_count <- max(matches)
  if (best_count == 0) {
    return(
      "Error: Did you upload the wrong file? The column names do not match the expected format."
    )
  }
  best <- names(which.max(matches))
  paste0(
    "Error: Did you upload the wrong file? This looks like it may be ",
    file_labels[[best]],
    "."
  )
}

# Raw read functions for each file type - mirrors the Excel import step of readMWR* without checks
raw_read_fns <- list(
  resdat = function(path) {
    suppressWarnings(
      readxl::read_excel(path, na = c("NA", "na", ""), guess_max = Inf)
    ) |>
      dplyr::mutate(dplyr::across(dplyr::everything(), as.character))
  },
  accdat = function(path) {
    dat <- readxl::read_excel(path, na = c("NA", ""), col_types = "text")
    if ("Value Range" %in% names(dat)) {
      dat <- dplyr::mutate(
        dat,
        dplyr::across(-c(`Value Range`), ~ dplyr::na_if(.x, "na"))
      )
    }
    dat
  },
  frecomdat = function(path) {
    suppressMessages(
      readxl::read_excel(
        path,
        skip = 1,
        na = c("NA", "na", ""),
        col_types = "text"
      )
    ) |>
      dplyr::rename(`% Completeness` = `...7`)
  },
  sitdat = function(path) readxl::read_excel(path, na = c("NA", "na", "")),
  wqxdat = function(path) {
    suppressWarnings(readxl::read_excel(
      path,
      na = c("NA", "na", ""),
      col_types = "text"
    ))
  },
  censdat = function(path) readxl::read_excel(path, na = c("NA", "na", ""))
)

# Retry functions: run check + format on an edited data frame from handsontable
retry_fns <- list(
  resdat = function(df) {
    if (
      "Activity Start Date" %in%
        names(df) &&
        !lubridate::is.POSIXct(df$`Activity Start Date`)
    ) {
      df$`Activity Start Date` <- as.POSIXct(
        as.character(df$`Activity Start Date`)
      )
    }
    formMWRresults(checkMWRresults(df, warn = TRUE))
  },
  accdat = function(df) formMWRacc(checkMWRacc(df, warn = TRUE)),
  frecomdat = function(df) formMWRfrecom(checkMWRfrecom(df, warn = TRUE)),
  sitdat = function(df) checkMWRsites(df),
  wqxdat = function(df) formMWRwqx(checkMWRwqx(df, warn = TRUE)),
  censdat = function(df) formMWRcens(checkMWRcens(df, warn = TRUE))
)

#' File status
#'
#' @description `fl_status` is a helper function to print file upload status in
#' cards.
#'
#' @param tester Boolean. If using test data, set to `TRUE`.
#' @param file_input Input data. Set to `NULL` if no data uploaded.
#' @param data_state String or dataframe. Set to `NULL` if error uploading data.
#'
#' @return HTML message
#'
#' @noRd
fl_status <- function(tester, file_input, data_state) {
  if (tester) {
    msg <- "<span style='color:#00A4CF'>Using test data</span>"
  } else if (is.null(file_input) && is.null(data_state)) {
    msg <- "No file uploaded"
  } else if (is.null(data_state)) {
    msg <- "<span style='color:#f54242'>Error loading</span>"
  } else if (is.null(file_input)) {
    msg <- "<span style='color:#64C147'>Loaded from format converter</span>"
  } else {
    msg <- "<span style='color:#64C147'>Data loaded</span>"
  }

  HTML(msg)
}
