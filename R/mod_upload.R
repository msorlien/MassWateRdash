#' upload UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_upload_ui <- function(id) {
  ns <- NS(id)

  tagList(
    bslib::page_sidebar(
      sidebar = bslib::sidebar(
        title = "Upload Data Files",
        width = 500,
        div(
          style = "display: flex; align-items: center; gap: 12px;",
          div(
            style = "flex: 0 0 auto;",
            shinyWidgets::materialSwitch("tester", "Test mode", FALSE)
          ),
          div(
            style = "flex: 1;",
            uiOutput("download_data_btn")
          )
        ),
        actionButton(
          "show_format_modal",
          "Convert from another format",
          icon  = icon("right-left"),
          width = "100%",
          class = "mb-3",
          style = "background-color: #64C147; border-color: #64C147; color: white;"
        ),
        fileInput(
          "resdat",
          "Upload Results Data (.xlsx)",
          accept = ".xlsx"
        ),
        fileInput(
          "accdat",
          "Upload DQO Accuracy Data (.xlsx)",
          accept = ".xlsx"
        ),
        fileInput(
          "frecomdat",
          "Upload DQO Frequency & Completeness Data (.xlsx)",
          accept = ".xlsx"
        ),
        fileInput(
          "sitdat",
          "Upload Site Data (.xlsx)",
          accept = ".xlsx"
        ),
        fileInput(
          "wqxdat",
          "Upload WQX Meta Data (.xlsx)",
          accept = ".xlsx"
        ),
        fileInput(
          "censdat",
          "Upload Censored Data (.xlsx) (optional)",
          accept = ".xlsx"
        )
      ),
      bslib::layout_columns(
        fill = FALSE,
        bslib::value_box(
          title = "Results Data",
          value = htmlOutput("resdat_status")
        ),
        bslib::value_box(
          title = "Accuracy Data",
          value = htmlOutput("accdat_status")
        ),
        bslib::value_box(
          title = "Frequency & Completeness Data",
          value = htmlOutput("frecomdat_status")
        ),
        bslib::value_box(
          title = "Sites Data",
          value = htmlOutput("sitdat_status")
        ),
        bslib::value_box(
          title = "WQX Data",
          value = htmlOutput("wqxdat_status")
        ),
        bslib::value_box(
          title = "Censored Data",
          value = htmlOutput("censdat_status")
        )
      ),
      bslib::card(
        bslib::card_header("Data Validation Messages"),
        uiOutput("validation_messages"),
        uiOutput("resdat_editor"),
        uiOutput("accdat_editor"),
        uiOutput("frecomdat_editor"),
        uiOutput("sitdat_editor"),
        uiOutput("wqxdat_editor"),
        uiOutput("censdat_editor")
      )
    )
  )
}

#' upload Server Functions
#'
#' @noRd
mod_upload_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Modules ----
    wqf <- mod_upload_format_server("prep")

    observe({
      req(wqf$dat_results())
      from_format_upload(wqf$dat_results(), retry_fns$resdat, "resdat")
      showNotification(
        "Results data loaded from format converter",
        type = "message",
        duration = 4
      )
    }) |>
      bindEvent(wqf$dat_results())

    observe({
      req(wqf$dat_sites())
      from_format_upload(wqf$dat_sites(), retry_fns$sitdat, "sitdat")
      showNotification(
        "Sites data loaded from format converter",
        type = "message",
        duration = 4
      )
    }) |>
      bindEvent(wqf$dat_sites())

    observe({
      showModal(modalDialog(
        title = "Convert from Another Format",
        mod_upload_format_ui("prep", in_modal = TRUE),
        size = "xl",
        footer = modalButton("Close"),
        easyClose = TRUE
      ))
    }) |>
      bindEvent(input$show_format_modal)

    # upload & validate -----
    # Reactive values to store validation messages and data states
    validation_log <<- reactiveVal("")
    data_states <<- reactiveValues(
      resdat = NULL,
      accdat = NULL,
      frecomdat = NULL,
      sitdat = NULL,
      wqxdat = NULL,
      censdat = NULL
    )
    raw_data_states <<- reactiveValues(
      resdat = NULL,
      accdat = NULL,
      frecomdat = NULL,
      sitdat = NULL,
      wqxdat = NULL,
      censdat = NULL
    )
    edit_visible <<- reactiveValues(
      resdat = FALSE,
      accdat = FALSE,
      frecomdat = FALSE,
      sitdat = FALSE,
      wqxdat = FALSE,
      censdat = FALSE
    )

    # Observers for each data upload
    observe({
      fl_upload(input$resdat, readMWRresults, "resdat")
    }) |>
      bindEvent(input$resdat)

    observe({
      fl_upload(input$accdat, readMWRacc, "accdat")
    }) |>
      bindEvent(input$accdat)

    observe({
      fl_upload(input$frecomdat, readMWRfrecom, "frecomdat")
    }) |>
      bindEvent(input$frecomdat)

    observe({
      fl_upload(input$sitdat, readMWRsites, "sitdat")
    }) |>
      bindEvent(input$sitdat)

    observe({
      fl_upload(input$wqxdat, readMWRwqx, "wqxdat")
    }) |>
      bindEvent(input$wqxdat)

    observe({
      fl_upload(input$censdat, readMWRcens, "censdat")
    }) |>
      bindEvent(input$censdat)

    # Status outputs
    output$resdat_status <- renderUI({
      fl_status(input$tester, input$resdat, data_states$resdat)
    })

    output$accdat_status <- renderUI({
      fl_status(input$tester, input$accdat, data_states$accdat)
    })

    output$frecomdat_status <- renderUI({
      fl_status(input$tester, input$frecomdat, data_states$frecomdat)
    })

    output$sitdat_status <- renderUI({
      fl_status(input$tester, input$sitdat, data_states$sitdat)
    })

    output$wqxdat_status <- renderUI({
      fl_status(input$tester, input$wqxdat, data_states$wqxdat)
    })

    output$censdat_status <- renderUI({
      fl_status(input$tester, input$censdat, data_states$censdat)
    })

    output$download_data_btn <- renderUI({
      any_loaded <- isTRUE(input$tester) ||
        any(!sapply(reactiveValuesToList(data_states), is.null))
      if (!any_loaded) {
        return(NULL)
      }
      dl_btn("download_data", "Download data", size = "sm")
    })

    output$download_data <- downloadHandler(
      filename = function() {
        paste0("MassWateR_data_", format(Sys.time(), "%Y%m%d"), ".zip")
      },
      content = function(file) {
        fls <- fsetls()
        file_map <- list(
          "results.csv"                = fls$res,
          "accuracy.csv"               = fls$acc,
          "frequency_completeness.csv" = fls$frecom,
          "sites.csv"                  = fls$sit,
          "wqx_metadata.csv"           = fls$wqx,
          "censored.csv"               = fls$cens
        )
        tmp_dir <- tempfile(pattern = "masswater_dl_")
        dir.create(tmp_dir)
        for (nm in names(file_map)) {
          df <- file_map[[nm]]
          if (!is.null(df)) {
            write.csv(df, file.path(tmp_dir, nm), row.names = FALSE)
          }
        }
        old_wd <- setwd(tmp_dir)
        on.exit(setwd(old_wd), add = TRUE)
        utils::zip(file, list.files(tmp_dir))
      }
    )

    # Output validation messages
    output$validation_messages <- renderUI({
      msg <- validation_log()
      if (nchar(trimws(msg)) == 0) {
        return(NULL)
      }
      msg <- gsub("\033\\[[0-9;]*[mGKHFABCDJK]", "", msg) # strip ANSI codes
      lines <- strsplit(msg, "\n")[[1]]
      lines <- lines[nchar(trimws(lines)) > 0]
      div(HTML(paste(lines, collapse = "<br>")))
    })

    # In-app data editors - shown when a file fails validation
    file_defs <- list(
      list(name = "resdat", label = "Results Data"),
      list(name = "accdat", label = "DQO Accuracy Data"),
      list(name = "frecomdat", label = "DQO Frequency & Completeness Data"),
      list(name = "sitdat", label = "Site Data"),
      list(name = "wqxdat", label = "WQX Meta Data"),
      list(name = "censdat", label = "Censored Data")
    )

    for (fd in file_defs) {
      local({
        nm <- fd$name
        lbl <- fd$label

        # Button shown inside the validation card when file has a validation error
        output[[paste0(nm, "_editor")]] <- renderUI({
          req(isTRUE(edit_visible[[nm]]))
          actionButton(paste0(nm, "_open_editor"), paste("Edit", lbl),
            class = "btn-warning", icon = icon("pencil")
          )
        })

        # Build modal with only the relevant card (no display:none needed)
        build_modal <- function(col_err) {
          modalDialog(
            title = paste("Edit", lbl, "- Fix Validation Errors"),
            size = "xl",
            easyClose = FALSE,
            uiOutput(paste0(nm, "_modal_msgs")),
            br(),
            p("Fix the issue below, then click 'Try upload again'."),
            if (col_err) {
              bslib::card(
                bslib::card_header("Column Names"),
                rhandsontable::rHandsontableOutput(paste0(nm, "_hot_headers"))
              )
            } else {
              bslib::card(
                bslib::card_header(
                  div(
                    class = "d-flex justify-content-between align-items-center w-100",
                    "Data",
                    uiOutput(paste0(nm, "_row_filter_ui"))
                  )
                ),
                rhandsontable::rHandsontableOutput(paste0(nm, "_hot"))
              )
            },
            footer = tagList(
              actionButton(
                paste0(nm, "_retry"),
                "Try upload again",
                class = "btn-primary"
              ),
              modalButton("Close")
            )
          )
        }

        observe({
          showModal(build_modal(is_column_error(validation_log())))
        }) |>
          bindEvent(input[[paste0(nm, "_open_editor")]])

        # Validation message shown inside the modal
        output[[paste0(nm, "_modal_msgs")]] <- renderUI({
          msg <- validation_log()
          if (nchar(trimws(msg)) == 0) {
            return(NULL)
          }
          msg <- gsub("\033\\[[0-9;]*[mGKHFABCDJK]", "", msg)
          lines <- strsplit(msg, "\n")[[1]]
          lines <- lines[nchar(trimws(lines)) > 0]
          div(HTML(paste(lines, collapse = "<br>")))
        })
        outputOptions(
          output,
          paste0(nm, "_modal_msgs"),
          suspendWhenHidden = FALSE
        )

        # Column names editor (renders even when modal is closed so it's ready on open)
        output[[paste0(nm, "_hot_headers")]] <- rhandsontable::renderRHandsontable({
          req(raw_data_states[[nm]])
          col_names <- names(raw_data_states[[nm]])
          locs <- parse_error_locations(validation_log())
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
                  renderer = 
                    "function(instance, td, row, col, prop, value, cellProperties) {
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
          paste0(nm, "_hot_headers"),
          suspendWhenHidden = FALSE
        )

        # Row filter toggle - shown in the Data card header when problem rows exist
        output[[paste0(nm, "_row_filter_ui")]] <- renderUI({
          problem_rows <- parse_problem_rows(validation_log())
          if (length(problem_rows) == 0) {
            return(NULL)
          }
          n_total <- if (!is.null(raw_data_states[[nm]])) nrow(raw_data_states[[nm]]) else 0
          div(
            class = "d-flex align-items-center gap-2",
            span(
              class = "badge bg-warning text-dark",
              paste(length(problem_rows), "row(s) with issues")
            ),
            checkboxInput(
              paste0(nm, "_show_all_rows"),
              paste0("show all ", n_total, " rows"),
              value = FALSE
            )
          )
        })
        outputOptions(
          output,
          paste0(nm, "_row_filter_ui"),
          suspendWhenHidden = FALSE
        )

        # Data editor - shows only problem rows by default when they exist
        output[[paste0(nm, "_hot")]] <- rhandsontable::renderRHandsontable({
          req(raw_data_states[[nm]])
          dat <- raw_data_states[[nm]]
          problem_rows <- parse_problem_rows(validation_log())
          locs <- parse_error_locations(validation_log(), names(dat))
          show_all <- isTRUE(input[[paste0(nm, "_show_all_rows")]])
          if (length(problem_rows) > 0 && !show_all) {
            valid_rows <- problem_rows[problem_rows >= 1 & problem_rows <= nrow(dat)]
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
              row_0 <- if (show_all && length(problem_rows) > 0) problem_rows - 1L else integer(0)
              if (length(row_0) == 0 && length(cell_0) == 0) next
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
          col_err <- is_column_error(validation_log())
          handle_retry(
            nm,
            hot_input         = if (!col_err) input[[paste0(nm, "_hot")]] else NULL,
            hot_headers_input = if (col_err) input[[paste0(nm, "_hot_headers")]] else NULL,
            show_all          = isTRUE(input[[paste0(nm, "_show_all_rows")]]),
            problem_rows      = parse_problem_rows(validation_log())
          )
          if (isTRUE(edit_visible[[nm]])) {
            new_col_err <- is_column_error(validation_log())
            if (new_col_err != col_err) {
              removeModal()
              showModal(build_modal(new_col_err))
            }
          }
        }) |>
          bindEvent(input[[paste0(nm, "_retry")]])
      })
    }

    # data inputs
    fsetls <- reactive({
      if (!input$tester) {
        resdat <- data_states$resdat
        accdat <- data_states$accdat
        frecomdat <- data_states$frecomdat
        sitdat <- data_states$sitdat
        wqxdat <- data_states$wqxdat
        censdat <- data_states$censdat
      }

      if (input$tester == TRUE) {
        resdat <- readMWRresults(
          system.file(
            "extdata",
            "ExampleResults.xlsx",
            package = "MassWateR"
          ),
          runchk = FALSE
        )
        accdat <- readMWRacc(
          system.file(
            "extdata",
            "ExampleDQOAccuracy.xlsx",
            package = "MassWateR"
          ),
          runchk = FALSE
        )
        frecomdat <- readMWRfrecom(
          system.file(
            "extdata",
            "ExampleDQOFrequencyCompleteness.xlsx",
            package = "MassWateR"
          ),
          runchk = FALSE
        )
        sitdat <- readMWRsites(
          system.file(
            "extdata", "ExampleSites.xlsx",
            package = "MassWateR"
          ),
          runchk = FALSE
        )
        wqxdat <- readMWRwqx(
          system.file(
            "extdata", "ExampleWQX.xlsx",
            package = "MassWateR"
          ),
          runchk = FALSE
        )
        censdat <- readMWRcens(
          system.file(
            "extdata", "ExampleCensored.xlsx",
            package = "MassWateR"
          ),
          runchk = FALSE
        )
      }

      out <- list(
        res = resdat,
        acc = accdat,
        frecom = frecomdat,
        sit = sitdat,
        wqx = wqxdat,
        cens = censdat
      )

      return(out)
    })
  })
}
