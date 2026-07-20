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
            uiOutput(ns("download_data_btn"))
          )
        ),
        actionButton(
          ns("show_format_modal"),
          "Convert from another format",
          icon = icon("right-left"),
          width = "100%",
          class = "mb-3",
          style = "background-color: #64C147; border-color: #64C147; color: white;"
        ),
        fileInput(
          ns("resdat"),
          "Upload Results Data (.xlsx)",
          accept = ".xlsx"
        ),
        fileInput(
          ns("accdat"),
          "Upload DQO Accuracy Data (.xlsx)",
          accept = ".xlsx"
        ),
        fileInput(
          ns("frecomdat"),
          "Upload DQO Frequency & Completeness Data (.xlsx)",
          accept = ".xlsx"
        ),
        fileInput(
          ns("sitdat"),
          "Upload Site Data (.xlsx)",
          accept = ".xlsx"
        ),
        fileInput(
          ns("wqxdat"),
          "Upload WQX Meta Data (.xlsx)",
          accept = ".xlsx"
        ),
        fileInput(
          ns("censdat"),
          "Upload Censored Data (.xlsx) (optional)",
          accept = ".xlsx"
        )
      ),
      bslib::layout_columns(
        fill = FALSE,
        bslib::value_box(
          title = "Results Data",
          value = htmlOutput(ns("resdat_status"))
        ),
        bslib::value_box(
          title = "Accuracy Data",
          value = htmlOutput(ns("accdat_status"))
        ),
        bslib::value_box(
          title = "Frequency & Completeness Data",
          value = htmlOutput(ns("frecomdat_status"))
        ),
        bslib::value_box(
          title = "Sites Data",
          value = htmlOutput(ns("sitdat_status"))
        ),
        bslib::value_box(
          title = "WQX Data",
          value = htmlOutput(ns("wqxdat_status"))
        ),
        bslib::value_box(
          title = "Censored Data",
          value = htmlOutput(ns("censdat_status"))
        )
      ),
      bslib::card(
        bslib::card_header("Data Validation Messages"),
        uiOutput(ns("validation_messages")),
        mod_upload_repair_ui("resdat_editor", "resdat"),
        mod_upload_repair_ui("accdat_editor", "accdat"),
        mod_upload_repair_ui("frecomdat_editor", "frecomdat"),
        mod_upload_repair_ui("sitdat_editor", "sitdat"),
        mod_upload_repair_ui("wqxdat_editor", "wqxdat"),
        mod_upload_repair_ui("censdat_editor", "censdat")
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

    # Reactive values -----
    val_log <- reactiveVal("")
    val_resdat <- reactiveValues(
      raw_dat_state = NULL,
      dat_state = NULL,
      del_dat_state = NULL,
      is_visible = FALSE
    )
    val_accdat <- reactiveValues(
      raw_dat_state = NULL,
      dat_state = NULL,
      del_dat_state = NULL,
      is_visible = FALSE
    )
    val_frecomdat <- reactiveValues(
      raw_dat_state = NULL,
      dat_state = NULL,
      del_dat_state = NULL,
      is_visible = FALSE
    )
    val_wqxdat <- reactiveValues(
      raw_dat_state = NULL,
      dat_state = NULL,
      del_dat_state = NULL,
      is_visible = FALSE
    )
    val_censdat <- reactiveValues(
      raw_dat_state = NULL,
      dat_state = NULL,
      del_dat_state = NULL,
      is_visible = FALSE
    )

    # Modules ----
    wqf <- mod_upload_format_server("reformat")
    mod_resdat <- mod_upload_repair_server(
      "resdat_editor",
      dat_name = "resdat",
      dat_values = reactive({
        val_resdat
      }),
      val_log = reactive({
        val_log()
      })
    )
    mod_accdat <- mod_upload_repair_server(
      "accdat_editor",
      dat_name = "accdat",
      dat_values = reactive({
        val_accdat
      }),
      val_log = reactive({
        val_log()
      })
    )
    mod_frecomdat <- mod_upload_repair_server(
      "frecomdat_editor",
      dat_name = "frecomdat",
      dat_values = reactive({
        val_frecomdat
      }),
      val_log = reactive({
        val_log()
      })
    )
    mod_wqxdat <- mod_upload_repair_server(
      "wqxdat_editor",
      dat_name = "resdat",
      dat_values = reactive({
        val_resdat
      }),
      val_log = reactive({
        val_log()
      })
    )
    mod_censdat <- mod_upload_repair_server(
      "censdat_editor",
      dat_name = "censdat",
      dat_values = reactive({
        val_censdat
      }),
      val_log = reactive({
        val_log()
      })
    )

    # Reformat data ----
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
      showModal(
        modalDialog(
          title = "Convert from Another Format",
          mod_upload_format_ui("reformat", in_modal = TRUE),
          size = "xl",
          footer = modalButton("Close"),
          easyClose = TRUE
        )
      )
    }) |>
      bindEvent(input$show_format_modal)

    # upload & validate -----
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

    # Status outputs ----
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

    # Downlaod data ----
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
          "results.csv" = fls$res,
          "accuracy.csv" = fls$acc,
          "frequency_completeness.csv" = fls$frecom,
          "sites.csv" = fls$sit,
          "wqx_metadata.csv" = fls$wqx,
          "censored.csv" = fls$cens
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

    # Validation messages -----
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

    # Output ----
    fsetls <- reactive({
      if (input$tester) {
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
            "extdata",
            "ExampleSites.xlsx",
            package = "MassWateR"
          ),
          runchk = FALSE
        )
        wqxdat <- readMWRwqx(
          system.file(
            "extdata",
            "ExampleWQX.xlsx",
            package = "MassWateR"
          ),
          runchk = FALSE
        )
        censdat <- readMWRcens(
          system.file(
            "extdata",
            "ExampleCensored.xlsx",
            package = "MassWateR"
          ),
          runchk = FALSE
        )
      } else {
        resdat <- val_resdat$data_state
        accdat <- val_accdat$data_state
        frecomdat <- val_frecomdat$data_state
        sitdat <- val_sitdat$data_state
        wqxdat <- val_wqxdat$data_state
        censdat <- val_censdat$data_state
      }

      list(
        res = resdat,
        acc = accdat,
        frecom = frecomdat,
        sit = sitdat,
        wqx = wqxdat,
        cens = censdat
      )
    })

    return(
      reactive({
        fsetls()
      })
    )
  })
}
