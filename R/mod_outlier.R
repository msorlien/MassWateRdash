#' outlier UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_outlier_ui <- function(id) {
  ns <- NS(id)
  tagList(
    bslib::page_sidebar(
      sidebar = bslib::sidebar(
        title = "Options",
        width = 500,
        uiOutput(ns("prm1")),
        uiOutput(ns("date_range")),
        selectInput(
          ns("group1"),
          "Group by",
          choices = c("month", "week", "site")
        ),
        selectInput(
          ns("type1"),
          "Plot type",
          choices = c("box", "jitterbox", "jitter")
        )
      ),
      bslib::navset_card_underline(
        full_screen = TRUE,
        bslib::nav_panel(
          "Plot",
          plotOutput("outlier_plot")
        ),
        bslib::nav_panel(
          "Table",
          reactable::reactableOutput("outlier_table")
        ),
        bslib::nav_panel(
          "Report",
          uiOutput("dwnldoutwrdbutt"),
          uiOutput("dwnldoutzipbutt")
        )
      )
    )
  )
}

#' outlier Server Functions
#'
#' @noRd
mod_outlier_server <- function(id, fsetls) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # reactive UI -----
    output$prm1 <- renderUI({
      # inputs
      fset <- fsetls()

      validate(
        need(!is.null(fset$res), 'Waiting for input data...')
      )

      tosel <- sort(unique(fset$res$`Characteristic Name`))

      selectInput("param1", "Parameter", choices = tosel)
    })

    output$date_range <- renderUI({
      # inputs
      param1 <- input$param1

      req(fsetls$res(), param1)

      tosel <- fsetls$res() |>
        dplyr::filter(`Characteristic Name` == param1) |>
        dplyr::pull(`Activity Start Date`) |>
        range() |>
        as.Date()

      sliderInput(
        "date_range",
        "Date range",
        min = tosel[1],
        max = tosel[2],
        value = tosel,
        width = '95%'
      )
    })

    # Plots ----
    output$outlier_plot <- renderPlot({
      # inputs
      param1 <- input$param1
      date_range <- as.character(input$date_range)
      group1 <- input$group1
      type1 <- input$type1

      req(fsetls$res(), fsetls$acc(), param1, date_range)

      anlzMWRoutlier(
        res = fsetls$res(),
        param = param1,
        acc = fsetls$acc(),
        group = group1,
        type = type1,
        dtrng = date_range,
        bssize = 18
      ) +
        ggplot2::labs(title = NULL)
    })

    output$outlier_table <- reactable::renderReactable({
      # inputs
      param1 <- input$param1
      date_range <- as.character(input$date_range)
      group1 <- input$group1
      type1 <- input$type1

      req(fsetls$res(), fsetls$acc(), param1, date_range)

      tab <- anlzMWRoutlier(
        res = fsetls$res(),
        param = param1,
        acc = fsetls$acc(),
        group = group1,
        dtrng = date_range,
        outliers = T
      )

      out <- reactable::reactable(
        tab,
        defaultColDef = reactable::colDef(
          footerStyle = list(fontWeight = "bold"),
          resizable = TRUE
        ),
        filterable = T
      )

      return(out)
    })

    # download outlier report word
    output$dwnldoutwrd <- downloadHandler(
      filename = function() {
        "outlierreport.docx"
      },
      content = function(file) {
        # inputs
        date_range <- as.character(input$date_range)
        group1 <- input$group1
        type1 <- input$type1

        anlzMWRoutlierall(
          fset = fsetls(),
          group = group1,
          type = type1,
          dtrng = date_range,
          format = "word",
          output_dir = dirname(file),
          output_file = basename(file)
        )
      }
    )

    # download outlier report zip
    output$dwnldoutzip <- downloadHandler(
      filename = function() {
        "outlierreport.zip"
      },
      content = function(file) {
        # inputs
        date_range <- as.character(input$date_range)
        group1 <- input$group1
        type1 <- input$type1

        anlzMWRoutlierall(
          fset = fsetls(),
          group = group1,
          type = type1,
          dtrng = date_range,
          format = "zip",
          output_dir = dirname(file),
          output_file = basename(file)
        )
      }
    )
  })
}
