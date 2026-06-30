#' Repair upload errors UI
#'
#' @description `mod_upload_repair_ui()` is a helper module for
#' `mod_upload_ui()`. It lets the user edit columns and variables in an
#' interactive process.
#'
#' @param id Namespace id for module. Should match `mod_upload_repair_server()`
#' id.
#' @param dat_label String. Dataset name. Used to label "Edit" button.
#'
#' @noRd
mod_upload_repair_ui <- function(id, dat_label) {
  ns <- NS(id)

  tagList(
    conditionalPanel(
      condition = paste0('output["', ns("show_btn"), '"] == "TRUE"'),
      actionButton(
        ns("open_editor"),
        paste("Edit", dat_label()),
        class = "btn-warning",
        icon = icon("pencil")
      )
    )
  )
}

#' Repair upload errors SERVER
#'
#' @description `mod_upload_repair_server()` is a helper module for
#' `mod_upload_server()`. It lets the user edit columns and variables in an
#' interactive process.
#'
#' @param id Namespace id for module. Should match `mod_upload_repair_ui()` id.
#' @param raw_dat Dataframe.
#' @param is_visible Boolean. If `TRUE`, show `ns("open_editor")`.
#' @param val_log String. Validation log.
#'
#' @noRd
mod_upload_repair_server <- function(
  id,
  raw_dat,
  is_visible,
  val_log
) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Toggle edit button visibility
    output$show_btn <- renderText({
      paste(is_visible())
    })
    outputOptions(output, "show_btn", suspendWhenHidden = FALSE)

    observe({
      showModal(
        build_modal(
          is_column_error(val_log())
        )
      )
    }) |>
      bindEvent(input$open_editor)

    # Validation message shown inside the modal
    output$modal_msgs <- renderUI({
      msg <- val_log()
      if (nchar(trimws(msg)) == 0) {
        return(NULL)
      }
      msg <- gsub("\033\\[[0-9;]*[mGKHFABCDJK]", "", msg)
      lines <- strsplit(msg, "\n")[[1]]
      lines <- lines[nchar(trimws(lines)) > 0]
      div(HTML(paste(lines, collapse = "<br>")))
    })
    outputOptions(output, "modal_msgs", suspendWhenHidden = FALSE)

    # Column names editor (renders even when modal is closed so it's ready on open)
    output$hot_headers <- rhandsontable::renderRHandsontable({
      req(raw_dat())

      col_names <- names(raw_dat())
      locs <- parse_error_locations(val_log())
      header_df <- setNames(
        as.data.frame(as.list(col_names), stringsAsFactors = FALSE),
        as.character(seq_along(col_names))
      )

      hot <- rhandsontable::rhandsontable(
        header_df,
        width = "100%",
        height = 75,
        rowHeaders = FALSE
      ) |>
        rhandsontable::hot_table(wordWrap = FALSE)

      for (idx in locs$col_indices) {
        if (idx >= 1 && idx <= length(col_names)) {
          hot <- hot |>
            rhandsontable::hot_col(
              idx,
              renderer = "function(instance, td, row, col, prop, value, cellProperties) {
                    Handsontable.renderers.TextRenderer.apply(this, arguments);
                    td.style.background = '#f8d7da';
                    td.style.fontWeight = 'bold';
                    }"
            )
        }
      }
      hot
    })
    outputOptions(
      output,
      "hot_headers",
      suspendWhenHidden = FALSE
    )

    # Row filter toggle - shown in the Data card header when problem rows exist
    output$row_filter_ui <- renderUI({
      problem_rows <- parse_problem_rows(val_log())
      if (length(problem_rows) == 0) {
        return(NULL)
      }
      n_total <- if (!is.null(raw_dat())) {
        nrow(raw_dat())
      } else {
        0
      }

      div(
        class = "d-flex align-items-center gap-2",
        span(
          class = "badge bg-warning text-dark",
          paste(length(problem_rows), "row(s) with issues")
        ),
        checkboxInput(
          "show_all_rows",
          paste0("show all ", n_total, " rows"),
          value = FALSE
        )
      )
    })
    outputOptions(output, "row_filter_ui", suspendWhenHidden = FALSE)

    # Data editor - shows only problem rows by default when they exist
    output$hot <- rhandsontable::renderRHandsontable({
      req(raw_dat())
      dat <- raw_dat()
      problem_rows <- parse_problem_rows(val_log())
      locs <- parse_error_locations(val_log(), names(dat))
      show_all <- isTRUE(input$show_all_rows)
      if (length(problem_rows) > 0 && !show_all) {
        valid_rows <- problem_rows[
          problem_rows >= 1 & problem_rows <= nrow(dat)
        ]
        dat <- dat[valid_rows, , drop = FALSE]
      }
      hot <- rhandsontable::rhandsontable(
        dat,
        width = "100%",
        height = 450
      ) |>
        rhandsontable::hot_table(wordWrap = FALSE)
      col_names <- names(dat)
      if (length(problem_rows) > 0 || length(locs$cell_map) > 0) {
        for (i in seq_along(col_names)) {
          cn <- col_names[i]
          col_bad <- locs$cell_map[[cn]]
          cell_0 <- if (!is.null(col_bad)) {
            if (!show_all && length(problem_rows) > 0) {
              which(problem_rows %in% col_bad) - 1L
            } else {
              col_bad - 1L
            }
          } else {
            integer(0)
          }
          row_0 <- if (show_all && length(problem_rows) > 0) {
            problem_rows - 1L
          } else {
            integer(0)
          }
          if (length(row_0) == 0 && length(cell_0) == 0) {
            next
          }
          hot <- hot |>
            rhandsontable::hot_col(
              i,
              renderer = sprintf(
                "function(instance, td, row, col, prop, value, cellProperties) {
                    Handsontable.renderers.TextRenderer.apply(this, arguments);
                    if ([%s].indexOf(row) > -1) { td.style.background = '#fff3cd'; }
                    if ([%s].indexOf(row) > -1) { td.style.background = '#ffc107'; }
                    }",
                paste(row_0, collapse = ","),
                paste(cell_0, collapse = ",")
              )
            )
        }
      }
      hot
    })
    outputOptions(output, paste0(nm, "_hot"), suspendWhenHidden = FALSE)

    observe({
      col_err <- is_column_error(val_log())
      handle_retry(
        nm,
        hot_input = if (!col_err) input$hot else NULL,
        hot_headers_input = if (col_err) {
          input$hot_headers
        } else {
          NULL
        },
        show_all = isTRUE(input$show_all_rows),
        problem_rows = parse_problem_rows(val_log())
      )
      if (is_visible) {
        new_col_err <- is_column_error(val_log())
        if (new_col_err != col_err) {
          removeModal()
          showModal(build_modal(new_col_err))
        }
      }
    }) |>
      bindEvent(input$retry)
  })
}
