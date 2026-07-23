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
            shinyWidgets::materialSwitch(ns("tester"), "Test mode", FALSE)
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

    # R6 classes ----
    val_log <- validationLog$new()

    # Reactive values -----
    edit_visible <- reactiveVal("")
    val_resdat <- reactiveValues(
      raw_dat_state = NULL,
      dat_state = NULL,
      del_dat_state = NULL
    )
    val_accdat <- reactiveValues(
      raw_dat_state = NULL,
      dat_state = NULL,
      del_dat_state = NULL
    )
    val_frecomdat <- reactiveValues(
      raw_dat_state = NULL,
      dat_state = NULL,
      del_dat_state = NULL
    )
    val_sitdat <- reactiveValues(
      raw_dat_state = NULL,
      dat_state = NULL,
      del_dat_state = NULL
    )
    val_wqxdat <- reactiveValues(
      raw_dat_state = NULL,
      dat_state = NULL,
      del_dat_state = NULL
    )
    val_censdat <- reactiveValues(
      raw_dat_state = NULL,
      dat_state = NULL,
      del_dat_state = NULL
    )

    # Modules ----
    wqf <- mod_upload_format_server("reformat")
    mod_resdat <- mod_upload_repair_server(
      "resdat_editor",
      dat_name = "resdat",
      dat_values = reactive({
        val_resdat
      }),
      val_log = val_log,
      edit_visible = reactive({
        edit_visible()
      })
    )
    mod_accdat <- mod_upload_repair_server(
      "accdat_editor",
      dat_name = "accdat",
      dat_values = reactive({
        val_accdat
      }),
      val_log = val_log,
      edit_visible = reactive({
        edit_visible()
      })
    )
    mod_frecomdat <- mod_upload_repair_server(
      "frecomdat_editor",
      dat_name = "frecomdat",
      dat_values = reactive({
        val_frecomdat
      }),
      val_log = val_log,
      edit_visible = reactive({
        edit_visible()
      })
    )
    mod_sitdat <- mod_upload_repair_server(
      "sitdat_editor",
      dat_name = "sitdat",
      dat_values = reactive({
        val_sitdat
      }),
      val_log = val_log,
      edit_visible = reactive({
        edit_visible()
      })
    )
    mod_wqxdat <- mod_upload_repair_server(
      "wqxdat_editor",
      dat_name = "wqxdat",
      dat_values = reactive({
        val_wqxdat
      }),
      val_log = val_log,
      edit_visible = reactive({
        edit_visible()
      })
    )
    mod_censdat <- mod_upload_repair_server(
      "censdat_editor",
      dat_name = "censdat",
      dat_values = reactive({
        val_censdat
      }),
      val_log = val_log,
      edit_visible = reactive({
        edit_visible()
      })
    )

    # Format data ----
    observe({
      req(wqf$dat_results())

      new_dat <- from_format_upload(
        wqf$dat_results(),
        retry_fns$resdat,
        "resdat"
      )
      showNotification(
        "Results data loaded from format converter",
        type = "message",
        duration = 4
      )

      val_log$msg <- new_dat$val_log
      edit_visible(new_dat$edit_visible)
      val_resdat$raw_dat_state <- new_dat$raw_dat_state
      val_resdat$dat_state <- new_dat$dat_state
    }) |>
      bindEvent(wqf$dat_results())

    observe({
      req(wqf$dat_sites())
      new_dat <- from_format_upload(wqf$dat_sites(), retry_fns$sitdat, "sitdat")
      showNotification(
        "Sites data loaded from format converter",
        type = "message",
        duration = 4
      )

      val_log$msg <- new_dat$val_log
      edit_visible(new_dat$edit_visible)
      val_sitdat$raw_dat_state <- new_dat$raw_dat_state
      val_sitdat$dat_state <- new_dat$dat_state
    }) |>
      bindEvent(wqf$dat_sites())

    observe({
      showModal(
        modalDialog(
          title = "Convert from Another Format",
          mod_upload_format_ui(ns("reformat"), in_modal = TRUE),
          size = "xl",
          footer = modalButton("Close"),
          easyClose = TRUE
        )
      )
    }) |>
      bindEvent(input$show_format_modal)

    # Upload & validate -----
    observe({
      new_dat <- fl_upload(input$resdat, readMWRresults, "resdat")

      val_log$msg <- new_dat$val_log
      edit_visible(new_dat$edit_visible)
      val_resdat$raw_dat_state <- new_dat$raw_dat_state
      val_resdat$dat_state <- new_dat$dat_state
    }) |>
      bindEvent(input$resdat)

    observe({
      new_dat <- fl_upload(input$accdat, readMWRacc, "accdat")

      val_log$msg <- new_dat$val_log
      edit_visible(new_dat$edit_visible)
      val_accdat$raw_dat_state <- new_dat$raw_dat_state
      val_accdat$dat_state <- new_dat$dat_state
    }) |>
      bindEvent(input$accdat)

    observe({
      new_dat <- fl_upload(input$frecomdat, readMWRfrecom, "frecomdat")

      val_log$msg <- new_dat$val_log
      edit_visible(new_dat$edit_visible)
      val_frecomdat$raw_dat_state <- new_dat$raw_dat_state
      val_frecomdat$dat_state <- new_dat$dat_state
    }) |>
      bindEvent(input$frecomdat)

    observe({
      new_dat <- fl_upload(input$sitdat, readMWRsites, "sitdat")

      val_log$msg <- new_dat$val_log
      edit_visible(new_dat$edit_visible)
      val_sitdat$raw_dat_state <- new_dat$raw_dat_state
      val_sitdat$dat_state <- new_dat$dat_state
    }) |>
      bindEvent(input$sitdat)

    observe({
      new_dat <- fl_upload(input$wqxdat, readMWRwqx, "wqxdat")

      val_log$msg <- new_dat$val_log
      edit_visible(new_dat$edit_visible)
      val_wqxdat$raw_dat_state <- new_dat$raw_dat_state
      val_wqxdat$dat_state <- new_dat$dat_state
    }) |>
      bindEvent(input$wqxdat)

    observe({
      new_dat <- fl_upload(input$censdat, readMWRcens, "censdat")

      val_log$msg <- new_dat$val_log
      edit_visible(new_dat$edit_visible)
      val_censdat$raw_dat_state <- new_dat$raw_dat_state
      val_censdat$dat_state <- new_dat$dat_state
    }) |>
      bindEvent(input$censdat)

    # Validation messages -----
    output$validation_messages <- renderUI({
      msg <- val_log$msg
      if (nchar(trimws(msg)) == 0) {
        return(NULL)
      }
      msg <- gsub("\033\\[[0-9;]*[mGKHFABCDJK]", "", msg) # strip ANSI codes
      lines <- strsplit(msg, "\n")[[1]]
      lines <- lines[nchar(trimws(lines)) > 0]
      div(HTML(paste(lines, collapse = "<br>")))
    })

    # Repair data ----
    observe({
      if (isTruthy(mod_resdat$edit_visible)) {
        edit_visible("resdat")
      } else {
        edit_visible("")
      }
      val_resdat$raw_dat_state <- mod_resdat$raw_dat_state
      val_resdat$dat_state <- mod_resdat$dat_state
      val_resdat$del_dat_state <- mod_resdat$del_dat_state
    }) |>
      bindEvent(mod_resdat)

    observe({
      if (isTruthy(mod_accdat$edit_visible)) {
        edit_visible("accdat")
      } else {
        edit_visible("")
      }
      val_accdat$raw_dat_state <- mod_accdat$raw_dat_state
      val_accdat$dat_state <- mod_accdat$dat_state
      val_accdat$del_dat_state <- mod_accdat$del_dat_state
    }) |>
      bindEvent(mod_accdat)

    observe({
      if (isTruthy(mod_frecomdat$edit_visible)) {
        edit_visible("frecomdat")
      } else {
        edit_visible("")
      }
      val_frecomdat$raw_dat_state <- mod_frecomdat$raw_dat_state
      val_frecomdat$dat_state <- mod_frecomdat$dat_state
      val_frecomdat$del_dat_state <- mod_frecomdat$del_dat_state
    }) |>
      bindEvent(mod_frecomdat)

    observe({
      if (isTruthy(mod_sitdat$edit_visible)) {
        edit_visible("sitdat")
      } else {
        edit_visible("")
      }
      val_sitdat$raw_dat_state <- mod_sitdat$raw_dat_state
      val_sitdat$dat_state <- mod_sitdat$dat_state
      val_sitdat$del_dat_state <- mod_sitdat$del_dat_state
    }) |>
      bindEvent(mod_sitdat)

    observe({
      if (isTruthy(mod_wqxdat$edit_visible)) {
        edit_visible("wqxdat")
      } else {
        edit_visible("")
      }
      val_wqxdat$raw_dat_state <- mod_wqxdat$raw_dat_state
      val_wqxdat$dat_state <- mod_wqxdat$dat_state
      val_wqxdat$del_dat_state <- mod_wqxdat$del_dat_state
    }) |>
      bindEvent(mod_wqxdat)

    observe({
      if (isTruthy(mod_censdat$edit_visible)) {
        edit_visible("censdat")
      } else {
        edit_visible("")
      }
      val_censdat$raw_dat_state <- mod_censdat$raw_dat_state
      val_censdat$dat_state <- mod_censdat$dat_state
      val_censdat$del_dat_state <- mod_censdat$del_dat_state
    }) |>
      bindEvent(mod_censdat)

    # Data Status ----
    output$resdat_status <- renderUI({
      fl_status(input$tester, input$resdat, val_resdat$dat_state)
    })

    output$accdat_status <- renderUI({
      fl_status(input$tester, input$accdat, val_accdat$dat_state)
    })

    output$frecomdat_status <- renderUI({
      fl_status(input$tester, input$frecomdat, val_frecomdat$dat_state)
    })

    output$sitdat_status <- renderUI({
      fl_status(input$tester, input$sitdat, val_sitdat$dat_state)
    })

    output$wqxdat_status <- renderUI({
      fl_status(input$tester, input$wqxdat, val_wqxdat$dat_state)
    })

    output$censdat_status <- renderUI({
      fl_status(input$tester, input$censdat, val_censdat$dat_state)
    })

    # Bundle data ----
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
        resdat <- val_resdat$dat_state
        accdat <- val_accdat$dat_state
        frecomdat <- val_frecomdat$dat_state
        sitdat <- val_sitdat$dat_state
        wqxdat <- val_wqxdat$dat_state
        censdat <- val_censdat$dat_state
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

    # Download data ----
    output$download_data_btn <- renderUI({
      any_loaded <- isTRUE(input$tester) || !is.null(unlist(fsetls()))

      if (!any_loaded) {
        return(NULL)
      }
      dl_btn(ns("download_data"), "Download data", size = "sm")
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

    # Module output ----
    return(
      reactive({
        fsetls()
      })
    )
  })
}
