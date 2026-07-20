#' Repair upload errors UI
#'
#' @description `mod_upload_repair_ui()` is a helper module for
#' `mod_upload_ui()`. It lets the user edit columns and variables in an
#' interactive process.
#'
#' @param id Namespace id for module. Should match `mod_upload_repair_server()`
#' id.
#' @param dat_name String. Short dataframe name.
#'
#' @noRd
mod_upload_repair_ui <- function(id, dat_name) {
  ns <- NS(id)

  tagList(
    conditionalPanel(
      condition = paste0('output["', ns("show_btn"), '"] == "TRUE"'),
      actionButton(
        ns("open_editor"),
        paste("Edit", unname(file_labels[dat_name])),
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
#' @param dat_name String. Short dataframe name.
#' @param dat_values Reactive list. Must contain items raw_dat_state, dat_state,
#' and del_dat_state.
#' @param val_log Reactive list. Must contain values items validation_log,
#' edit_visible.
#'
#' @noRd
mod_upload_repair_server <- function(id, dat_name, dat_values, dat_status) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Set reactive values ----
    val <- reactiveValues(
      val_log = "",
      raw_dat_state = NULL,
      dat_state = NULL,
      del_dat_state = NULL,
      edit_visible = FALSE
    )

    observe({
      if (dat_status$edit_visible() == dat_name) {
        val$edit_visible <- TRUE
      } else {
        val$edit_visible <- FALSE
      }
    }) |>
      bindEvent(dat_status$edit_visible())

    # Toggle edit button visibility
    output$show_btn <- renderText({
      paste(val$edit_visible)
    })
    outputOptions(output, "show_btn", suspendWhenHidden = FALSE)

    # Update reactive values when "Edit" button selected
    observe({
      val$val_log <- dat_status$validation_log()
      val$raw_dat_state <- dat_values$raw_dat_state()
      val$dat_state <- dat_values$dat_state()
      val$del_dat_state <- dat_values$del_dat_state()
    }) |>
      bindEvent(input$open_editor)

    # Create modal ----
    observe({
      showModal(
        modalDialog(
          title = paste(
            "Edit",
            unname(file_labels[dat_name]),
            "- Fix Validation Errors"
          ),
          size = "xl",
          easyClose = FALSE,
          uiOutput(ns("modal_msgs")),
          br(),
          p("Fix the issue below, then click 'Try upload again'."),
          if (is_column_error(val$val_log)) {
            bslib::card(
              bslib::card_header("Column Names"),
              rhandsontable::rHandsontableOutput(ns("hot_headers"))
            )
          } else {
            bslib::card(
              bslib::card_header(
                div(
                  class = "d-flex justify-content-between align-items-center w-100",
                  "Data",
                  uiOutput(ns("row_filter_ui"))
                )
              ),
              rhandsontable::rHandsontableOutput(ns("hot"))
            )
          },
          footer = tagList(
            actionButton(
              ns("retry"),
              "Try upload again",
              class = "btn-primary"
            ),
            modalButton("Close")
          )
        )
      )
    }) |>
      bindEvent(input$open_editor)

    # Validation message shown inside the modal
    output$modal_msgs <- renderUI({
      msg <- val$val_log
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
      req(val$raw_dat_state)

      col_names <- names(val$raw_dat_state)
      locs <- parse_error_locations(val$val_log)
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
    outputOptions(output, "hot_headers", suspendWhenHidden = FALSE)

    # Row filter toggle - shown in the Data card header when problem rows exist
    output$row_filter_ui <- renderUI({
      problem_rows <- parse_problem_rows(val$val_log)
      if (length(problem_rows) == 0) {
        return(NULL)
      }
      n_total <- if (!is.null(val$raw_dat_state)) nrow(val$raw_dat_state) else 0

      div(
        class = "d-flex align-items-center gap-2",
        span(
          class = "badge bg-warning text-dark",
          paste(length(problem_rows), "row(s) with issues")
        ),
        checkboxInput(
          ns("show_all_rows"),
          paste0("show all ", n_total, " rows"),
          value = FALSE
        )
      )
    })
    outputOptions(output, "row_filter_ui", suspendWhenHidden = FALSE)

    # Data editor - shows only problem rows by default when they exist
    output$hot <- rhandsontable::renderRHandsontable({
      req(val$raw_dat_state)
      dat <- val$raw_dat_state
      problem_rows <- parse_problem_rows(val$val_log)
      locs <- parse_error_locations(val$val_log, names(dat))
      show_all <- isTRUE(input$show_all_rows)
      if (length(problem_rows) > 0 && !show_all) {
        valid_rows <- problem_rows[
          problem_rows >= 1 & problem_rows <= nrow(dat)
        ]
        dat <- dat[valid_rows, , drop = FALSE]
      }

      hot <- rhandsontable::rhandsontable(dat, width = "100%", height = 450) |>
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
    outputOptions(output, "hot", suspendWhenHidden = FALSE)

    # Retry ----
    observe({
      col_err <- is_column_error(val$val_log)
      new_dat <- handle_retry(
        dat_name,
        raw_dat_state = val$raw_dat_state,
        edit_visible = val$edit_visible,
        hot_input = if (!col_err) input$hot else NULL,
        hot_headers_input = if (col_err) input$hot_headers else NULL,
        show_all = isTRUE(input$show_all_rows),
        problem_rows = parse_problem_rows(val$val_log)
      )

      val$val_log <- new_dat$val_log
      val$raw_dat_state <- new_dat$raw_dat_state
      val$dat_state <- new_dat$dat_state
      val$edit_visible <- new_dat$edit_visible

      if (!val$edit_visible) removeModal()
    }) |>
      bindEvent(input$retry)

    # Return data ----
    return(
      list(
        val_log = reactive({
          val$val_log
        }),
        edit_visible = reactive({
          val$edit_visible
        }),
        raw_dat_state = reactive({
          val$raw_dat_state
        }),
        dat_state <- reactive({
          new_dat$dat_state
        }),
        del_dat_state = reactive({
          val$del_dat_state
        })
      )
    )
  })
}
