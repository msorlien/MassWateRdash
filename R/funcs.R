# Function to capture and log messages
capture_messages <- function(expr) {
  # Create a text connection to capture output
  temp <- textConnection("messages", "w", local = TRUE)
  sink(temp, type = "message")
  on.exit({
    sink(type = "message")
    close(temp)
  })
  
  result <- expr
  
  # Get the captured messages
  if(exists("messages")) {
    current_log <- validation_log()
    new_msgs <- paste(messages, collapse = "\n")
    validation_log(paste0(current_log, if(nchar(current_log) > 0) "\n", new_msgs))
  }
  
  return(result)
}

# Distinctive columns unique to each file type — used to detect wrong-file uploads
file_signatures <- list(
  resdat    = c("Activity Type", "Characteristic Name", "Result Value"),
  accdat    = c("Value Range", "MDL"),
  frecomdat = c("% Completeness"),
  sitdat    = c("Monitoring Location Latitude", "Monitoring Location Longitude"),
  wqxdat    = c("Sampling Method Context", "Analytical Method Context"),
  censdat = c("Parameter", "Missed and Censored Records")
)

file_labels <- c(
  resdat    = "Results data",
  accdat    = "DQO Accuracy data",
  frecomdat = "DQO Frequency & Completeness data",
  sitdat    = "Site data",
  wqxdat    = "WQX metadata",
  censdat = "Censored data"
)

is_column_error <- function(msg) {
  if (is.null(msg) || nchar(trimws(msg)) == 0) return(FALSE)
  grepl("correct the column names|Missing the following columns", msg)
}

detect_wrong_file <- function(raw_df, data_name) {
  if (is.null(raw_df)) return(NULL)
  cols <- names(raw_df)
  if (any(file_signatures[[data_name]] %in% cols)) return(NULL)
  matches <- sapply(file_signatures, function(sigs) sum(sigs %in% cols))
  best_count <- max(matches)
  if (best_count == 0)
    return("Error: Did you upload the wrong file? The column names do not match the expected format.")
  best <- names(which.max(matches))
  paste0("Error: Did you upload the wrong file? This looks like it may be ", file_labels[[best]], ".")
}

# Raw read functions for each file type - mirrors the Excel import step of readMWR* without checks
raw_read_fns <- list(
  resdat = function(path) {
    suppressWarnings(readxl::read_excel(path, na = c('NA', 'na', ''), guess_max = Inf)) |>
      dplyr::mutate(dplyr::across(dplyr::everything(), as.character))
  },
  accdat = function(path) {
    dat <- readxl::read_excel(path, na = c('NA', ''), col_types = 'text')
    if ('Value Range' %in% names(dat))
      dat <- dplyr::mutate(dat, dplyr::across(-c(`Value Range`), ~ dplyr::na_if(.x, 'na')))
    dat
  },
  frecomdat = function(path) {
    suppressMessages(
      readxl::read_excel(path, skip = 1, na = c('NA', 'na', ''),
        col_types = 'text')
    ) |> dplyr::rename(`% Completeness` = `...7`)
  },
  sitdat    = function(path) readxl::read_excel(path, na = c('NA', 'na', '')),
  wqxdat    = function(path) suppressWarnings(readxl::read_excel(path, na = c('NA', 'na', ''), col_types = 'text')),
  censdat = function(path) readxl::read_excel(path, na = c('NA', 'na', ''))
)

# Retry functions: run check + format on an edited data frame from handsontable
retry_fns <- list(
  resdat = function(df) {
    if ('Activity Start Date' %in% names(df) && !lubridate::is.POSIXct(df$`Activity Start Date`))
      df$`Activity Start Date` <- as.POSIXct(as.character(df$`Activity Start Date`))
    formMWRresults(checkMWRresults(df, warn = TRUE))
  },
  accdat = function(df) formMWRacc(checkMWRacc(df, warn = TRUE)),
  frecomdat = function(df) formMWRfrecom(checkMWRfrecom(df, warn = TRUE)),
  sitdat    = function(df) checkMWRsites(df),
  wqxdat    = function(df) formMWRwqx(checkMWRwqx(df, warn = TRUE)),
  censdat = function(df) formMWRcens(checkMWRcens(df, warn = TRUE))
)

# file upload for observers
fl_upload <- function(file, read_function, data_name) {
  req(file)
  validation_log("")
  for (nm in names(reactiveValuesToList(edit_visible))) {
    edit_visible[[nm]] <- FALSE
  }
  raw_data_states[[data_name]] <- NULL

  result <- tryCatch({
    capture_messages(read_function(file$datapath))
  }, error = function(e) {
    raw <- tryCatch(raw_read_fns[[data_name]](file$datapath), error = function(e2) NULL)
    wrong_file_msg <- detect_wrong_file(raw, data_name)
    if (!is.null(wrong_file_msg)) {
      validation_log(wrong_file_msg)
    } else {
      validation_log(paste0("Error in ", data_name, ": ", e$message))
      raw_data_states[[data_name]] <<- raw
      edit_visible[[data_name]] <<- !is.null(raw)
    }
    NULL
  })

  data_states[[data_name]] <- result
}

# upload handler for data already converted in memory (e.g. from Format tab)
from_format_upload <- function(df, retry_fn, data_name) {
  validation_log("")
  for (nm in names(reactiveValuesToList(edit_visible))) {
    edit_visible[[nm]] <- FALSE
  }
  raw_data_states[[data_name]] <- NULL

  result <- tryCatch({
    capture_messages(retry_fn(df))
  }, error = function(e) {
    validation_log(paste0("Error processing ", data_name, ": ", e$message))
    raw_data_states[[data_name]] <<- df
    edit_visible[[data_name]] <<- TRUE
    NULL
  })

  data_states[[data_name]] <- result
}

# Parse row indices from a validation message (e.g. "in row(s) 3, 7, 45")
parse_problem_rows <- function(msg) {
  if (is.null(msg) || nchar(trimws(msg)) == 0) return(integer(0))
  msg <- gsub("\033\\[[0-9;]*[mGKHFABCDJK]", "", msg)
  hits <- regmatches(msg, gregexpr("row\\(s\\)\\s+([0-9, ]+)", msg, perl = TRUE))[[1]]
  if (length(hits) == 0) return(integer(0))
  nums <- gsub("row\\(s\\)\\s+", "", hits)
  rows <- suppressWarnings(as.integer(unlist(strsplit(nums, "[, ]+"))))
  sort(unique(rows[!is.na(rows)]))
}

# Parse column indices and a column->row cell map from a validation message.
# col_indices: 1-based positions flagged via "(column N)" — for header highlighting.
# cell_map:    named list col_name -> row_indices for cell-level highlighting.
#   Pattern A: "ColName (row(s) N, M)" explicit pairing (frecomdat/accdat style).
#   Pattern B: a known column name appears in the same line as "row(s) N".
parse_error_locations <- function(msg, col_names = NULL) {
  empty <- list(col_indices = integer(0), cell_map = list())
  if (is.null(msg) || nchar(trimws(msg)) == 0) return(empty)
  msg <- gsub("\033\\[[0-9;]*[mGKHFABCDJK]", "", msg)

  col_idx_hits <- regmatches(msg, gregexpr("\\(column (\\d+)\\)", msg, perl = TRUE))[[1]]
  col_indices <- sort(unique(suppressWarnings(as.integer(gsub("[^0-9]", "", col_idx_hits)))))
  col_indices <- col_indices[!is.na(col_indices)]

  cell_map <- list()

  for (ln in strsplit(msg, "\n")[[1]]) {
    if (!grepl("row\\(s\\)", ln)) next

    pA <- regmatches(ln, gregexpr("([^,\n]+?)\\s+\\(row\\(s\\)\\s+[\\d, ]+\\)", ln, perl = TRUE))[[1]]
    if (length(pA) > 0) {
      for (hit in pA) {
        col_nm   <- trimws(sub("\\s*\\(row\\(s\\).*", "", hit))
        rows_str <- regmatches(hit, regexpr("row\\(s\\)\\s+[\\d, ]+", hit))
        rows <- sort(unique(suppressWarnings(as.integer(
          unlist(strsplit(gsub("row\\(s\\)\\s+", "", rows_str), "[, ]+"))
        ))))
        rows <- rows[!is.na(rows)]
        if (nchar(col_nm) > 0 && length(rows) > 0)
          cell_map[[col_nm]] <- sort(unique(c(cell_map[[col_nm]], rows)))
      }
      next
    }

    if (!is.null(col_names)) {
      rows_str <- regmatches(ln, gregexpr("row\\(s\\)\\s+[\\d, ]+", ln, perl = TRUE))[[1]]
      rows <- sort(unique(suppressWarnings(as.integer(
        unlist(strsplit(gsub("row\\(s\\)\\s+", "", rows_str), "[, ]+"))
      ))))
      rows <- rows[!is.na(rows)]
      if (length(rows) > 0) {
        for (cn in col_names) {
          if (grepl(cn, ln, fixed = TRUE))
            cell_map[[cn]] <- sort(unique(c(cell_map[[cn]], rows)))
        }
      }
    }
  }

  list(col_indices = col_indices, cell_map = cell_map)
}

# Handle retry after user edits in handsontable
# show_all: TRUE when the user toggled to full-table view (no row merge needed)
# problem_rows: indices that were displayed in filtered view
handle_retry <- function(data_name, hot_input, hot_headers_input = NULL,
                         show_all = TRUE, problem_rows = integer(0)) {
  validation_log("")

  if (!is.null(hot_input)) {
    edited_df <- rhandsontable::hot_to_r(hot_input)
  } else {
    req(raw_data_states[[data_name]])
    edited_df <- raw_data_states[[data_name]]
  }

  # Apply any edited column names from the header editor
  if (!is.null(hot_headers_input)) {
    new_names <- unlist(rhandsontable::hot_to_r(hot_headers_input)[1, ], use.names = FALSE)
    if (length(new_names) == ncol(edited_df))
      names(edited_df) <- new_names
  }

  # When filtered view was active, merge the edited subset back into the full data
  if (!show_all && length(problem_rows) > 0 && !is.null(raw_data_states[[data_name]])) {
    full_df <- raw_data_states[[data_name]]
    names(full_df) <- names(edited_df)
    valid_rows <- problem_rows[problem_rows >= 1 & problem_rows <= nrow(full_df)]
    full_df[valid_rows, ] <- edited_df[seq_along(valid_rows), ]
    edited_df <- full_df
  }

  # Persist edits into raw_data_states so they survive a failed retry and the
  # re-rendered table reflects the user's work on the next round of checks
  raw_data_states[[data_name]] <<- edited_df

  result <- tryCatch({
    capture_messages(retry_fns[[data_name]](edited_df))
  }, error = function(e) {
    validation_log(paste0("Error in ", data_name, ": ", e$message))
    NULL
  })

  data_states[[data_name]] <- result
  if (!is.null(result)) {
    edit_visible[[data_name]] <- FALSE
    raw_data_states[[data_name]] <<- NULL
    removeModal()
  }
}

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
  if (tester) return(HTML("<span style='color:#00A4CF'>Using test data</span>"))
  if (is.null(file_input) && is.null(data_state)) return(HTML("No file uploaded"))
  if (is.null(data_state)) return(HTML("<span style='color:#f54242'>Error loading</span>"))
  if (is.null(file_input)) HTML("<span style='color:#64C147'>Loaded from format converter</span>")
  else HTML("<span style='color:#64C147'>Data loaded</span>")
}

# dqo table theme
thmdqo <- function(x, dqofontsize, padding){
  flextable::colformat_double(x, na_str = '-') |> 
    flextable::colformat_char(na_str = '-') |> 
    flextable::border_inner() |> 
    flextable::align(align = 'center', part = 'all') |> 
    flextable::align(align = 'left', j = 1, part = 'all') |> 
    flextable::fontsize(size = dqofontsize, part = 'all') |> 
    flextable::padding(padding = padding, part = 'all')
}

# dqo summary table theme
thmsum <- function(x, wd){
  if(!is.null(x))
    flextable::width(x, width = wd / flextable::ncol_keys(x))
}

# frecomdat table
frecomdat_tab <- function(frecomdat, dqofontsize, padding, wd){

  frecomdat |> 
    dplyr::mutate_if(is.numeric, as.character) |> 
    dplyr::mutate_all(function(x) ifelse(is.na(x), '-', x)) |> 
    dplyr::arrange(.data$Parameter, .locale = 'en') |> 
    flextable::flextable() |> 
    thmdqo(dqofontsize = dqofontsize, padding = padding) |>
    flextable::width(width = wd / ncol(frecomdat)) |>
    flextable::add_header_row(value = c('', 'Frequency %', ''), colwidths = c(1, 5, 1)) |> 
    flextable::set_caption("Frequency and Completeness") |> 
    flextable::htmltools_value()
  
}

# accdat table
accdat_tab <- function(accdat, dqofontsize, padding, wd){
  
  out <- accdat |> 
    dplyr::mutate_if(is.numeric, as.character) |> 
    dplyr::mutate_all(function(x) ifelse(is.na(x), '-', x)) |> 
    dplyr::arrange(.data$Parameter, .locale = 'en') |> 
    flextable::flextable() |> 
    thmdqo(dqofontsize = dqofontsize, padding = padding) |> 
    flextable::width(width = 1, j = 1) 
  
  out <- out |> 
    flextable::width(width = (wd -1) / (flextable::ncol_keys(out) - 1), j = 2:flextable::ncol_keys(out)) |> 
    flextable::set_caption("Accuracy") |> 
    flextable::htmltools_value()
  
  return(out)
  
}

#' Create dropdown menu
#'
#' @description `dropdown()` creates a dropdown widget.
#'
#' @param id String. Widget id.
#' @param label String. Widget heading/label.
#' @param choices List. Dropdown choices.
#' @param choice_names List. Display names for choices. Default `NULL`.
#' @param sorted Boolean. Whether to sort the choices. Default `TRUE`.
#' @param decreasing Boolean. Whether to sort choices in descending order.
#' Default `FALSE`.
#' @param multiple Boolean. Whether to allow multiple selections. Default
#' `TRUE`.
#' @param max_options Integer. Maximum number of selections. Default `NULL`.
#'
#' @return A dropdown widget.
#'
#' @noRd
dropdown <- function(
    id, label, choices, choice_names = NULL, sorted = TRUE,
    decreasing = FALSE, multiple = TRUE, max_options = NULL
) {
  if (!is.null(choice_names)) {
    names(choices) <- choice_names
  }
  
  choices <- choices[!duplicated(choices)]
  
  if (sorted && is.null(choice_names)) {
    choices <- sort(choices, decreasing = decreasing)
  } else if (sorted) {
    choices <- choices[order(names(choices), decreasing = decreasing)]
  }
  
  selected <- choices[1]
  allow_actions <- FALSE
  if (multiple && is.null(max_options)) {
    selected <- choices
    allow_actions <- TRUE
  }
  
  shinyWidgets::pickerInput(
    id,
    label = label,
    choices = choices,
    selected = selected,
    options = list(
      `actions-box` = allow_actions,
      `live-search` = TRUE,
      `selected-text-format` = "count > 1",
      `max-options` = max_options,
      container = "body"
    ),
    multiple = multiple
  )
}

dl_btn <- function(id, label, block = TRUE, size = "md") {
  btn <- shinyWidgets::downloadBttn(id, label = label, style = "simple", block = block, size = size)
  htmltools::tagAppendAttributes(
    btn,
    style = "background-color: #64C147 !important; border-color: #64C147 !important; color: white !important;"
  )
}