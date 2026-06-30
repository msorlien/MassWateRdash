#' visualize UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_visualize_ui <- function(id) {
  ns <- NS(id)
  tagList(
    bslib::page_sidebar(
      sidebar = bslib::sidebar(
        title = "Plot options",
        width = 500,
        uiOutput("prm2"),
        uiOutput("dtrng2"),
        uiOutput("sites2"),
        uiOutput("notmap"),
        uiOutput("vizui"),
        uiOutput("confint_ui"),
        uiOutput("download_plot_btn")
      ),
      bslib::navset_card_underline(
        full_screen = T,
        id = "viz_selected",
        bslib::nav_panel(
          "Season",
          plotOutput("season_plot")
        ),
        bslib::nav_panel(
          "Date",
          plotOutput("date_plot")
        ),
        bslib::nav_panel(
          "Site",
          plotOutput("site_plot")
        ),
        bslib::nav_panel(
          "Map",
          selectInput(
            "watsel",
            "Water feature detail",
            choices = c("low", "medium", "high", "none" = "NULL")
          ),
          selectInput(
            "mapsel",
            "Basemap selection",
            choices = c(
              "none" = "NULL", "OpenStreetMap", "OpenStreetMap.DE",
              "OpenStreetMap.France", "OpenStreetMap.HOT", "OpenTopoMap",
              "Esri.WorldStreetMap", "Esri.DeLorme", "Esri.WorldTopoMap",
              "Esri.WorldImagery", "Esri.WorldTerrain",
              "Esri.WorldShadedRelief", "Esri.OceanBasemap",
              "Esri.NatGeoWorldMap", "Esri.WorldGrayCanvas", "CartoDB.Positron",
              "CartoDB.PositronNoLabels", "CartoDB.PositronOnlyLabels",
              "CartoDB.DarkMatter", "CartoDB.DarkMatterNoLabels",
              "CartoDB.DarkMatterOnlyLabels", "CartoDB.Voyager",
              "CartoDB.VoyagerNoLabels", "CartoDB.VoyagerOnlyLabels"
            )
          ),
          plotOutput("map_plot")
        )
      )
    )
  )
}

#' visualize Server Functions
#'
#' @noRd
mod_visualize_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    output$download_plot_btn <- renderUI({
      req(fsetls()$res, input$param2)
      actionButton(
        "open_plot_download", "Download plot",
        icon = icon("download"),
        width = "100%",
        style = "background-color: #64C147; border-color: #64C147; color: white;"
      )
    })

    observe({
      showModal(modalDialog(
        title = "Download plot",
        size = "s",
        numericInput("plot_width", "Width (inches)", value = 10, min = 1, max = 30),
        numericInput("plot_height", "Height (inches)", value = 6, min = 1, max = 30),
        numericInput("plot_dpi", "Resolution (DPI)", value = 150, min = 72, max = 600),
        selectInput("plot_format", "Format",
          choices = c("PNG" = "png", "PDF" = "pdf", "SVG" = "svg")
        ),
        footer = tagList(
          dl_btn("download_plot", "Download"),
          modalButton("Cancel")
        ),
        easyClose = TRUE
      ))
    }) |>
      bindEvent(input$open_plot_download)

    output$download_plot <- downloadHandler(
      filename = function() {
        paste0(input$param2, "_", tolower(input$viz_selected), ".", input$plot_format)
      },
      content = function(file) {
        fset <- fsetls()
        viz <- input$viz_selected
        param2 <- input$param2
        dtrng2 <- as.character(input$dtrng2)
        sites2 <- input$sites2
        thresh <- if (is.null(input$thresh)) "none" else input$thresh
        confint2 <- isTRUE(as.logical(input$confint2))

        p <- if (viz == "Season") {
          anlzMWRseason(
            res = fset$res, param = param2, acc = fset$acc, sit = fset$sit,
            thresh = thresh, type = input$type2, dtrng = dtrng2,
            site = sites2, confint = confint2, bssize = 18
          ) +
            ggplot2::labs(title = NULL)
        } else if (viz == "Date") {
          anlzMWRdate(
            res = fset$res, param = param2, acc = fset$acc, sit = fset$sit,
            thresh = thresh, group = input$group2, dtrng = dtrng2,
            site = sites2, confint = confint2, bssize = 18
          ) +
            ggplot2::labs(title = NULL)
        } else if (viz == "Site") {
          anlzMWRsite(
            res = fset$res, param = param2, acc = fset$acc, sit = fset$sit,
            thresh = thresh, type = input$type2, dtrng = dtrng2,
            site = sites2, confint = confint2, bssize = 18
          ) +
            ggplot2::labs(title = NULL)
        } else {
          watsel <- if (isTRUE(input$watsel == "NULL")) NULL else input$watsel
          mapsel <- if (isTRUE(input$mapsel == "NULL")) NULL else input$mapsel
          anlzMWRmap(
            res = fset$res, param = param2, acc = fset$acc, sit = fset$sit,
            dtrng = dtrng2, site = sites2, addwater = watsel,
            maptype = mapsel, bssize = 18
          ) +
            ggplot2::labs(title = NULL)
        }

        ggplot2::ggsave(
          filename = file,
          plot     = p,
          width    = input$plot_width,
          height   = input$plot_height,
          dpi      = input$plot_dpi,
          device   = input$plot_format
        )
      }
    )

    output$season_plot <- renderPlot({
      # inputs
      thresh <- if (is.null(input$thresh)) "none" else input$thresh
      param2 <- input$param2
      dtrng2 <- as.character(input$dtrng2)
      sites2 <- input$sites2
      type2 <- input$type2
      confint2 <- isTRUE(as.logical(input$confint2))

      req(fsetls()$res, fsetls()$acc, param2, dtrng2, sites2)
      req(all(sites2 %in% valid_sites2()))

      anlzMWRseason(res = fsetls()$res, param = param2, acc = fsetls()$acc, sit = fsetls()$sit, thresh = thresh, type = type2, dtrng = dtrng2, site = sites2, confint = confint2, bssize = 18, warn = FALSE) +
        ggplot2::labs(title = NULL)
    })

    output$date_plot <- renderPlot({
      # inputs
      thresh <- if (is.null(input$thresh)) "none" else input$thresh
      param2 <- input$param2
      dtrng2 <- as.character(input$dtrng2)
      sites2 <- input$sites2
      group2 <- input$group2
      confint2 <- isTRUE(as.logical(input$confint2))

      req(fsetls()$res, fsetls()$acc, param2, dtrng2, sites2)
      req(all(sites2 %in% valid_sites2()))

      anlzMWRdate(res = fsetls()$res, param = param2, acc = fsetls()$acc, sit = fsetls()$sit, thresh = thresh, group = group2, dtrng = dtrng2, site = sites2, confint = confint2, bssize = 18, warn = FALSE) +
        ggplot2::labs(title = NULL)
    })

    output$site_plot <- renderPlot({
      # inputs
      thresh <- if (is.null(input$thresh)) "none" else input$thresh
      param2 <- input$param2
      dtrng2 <- as.character(input$dtrng2)
      sites2 <- input$sites2
      type2 <- input$type2
      confint2 <- isTRUE(as.logical(input$confint2))

      req(fsetls()$res, fsetls()$acc, param2, dtrng2, sites2)
      req(all(sites2 %in% valid_sites2()))

      anlzMWRsite(res = fsetls()$res, param = param2, acc = fsetls()$acc, sit = fsetls()$sit, thresh = thresh, type = type2, dtrng = dtrng2, site = sites2, confint = confint2, bssize = 18, warn = FALSE) +
        ggplot2::labs(title = NULL)
    })

    output$map_plot <- renderPlot({
      # inputs
      param2 <- input$param2
      dtrng2 <- as.character(input$dtrng2)
      sites2 <- input$sites2
      watsel <- input$watsel
      mapsel <- input$mapsel

      req(fsetls()$res, fsetls()$acc, fsetls()$sit, param2, dtrng2, sites2)
      req(all(sites2 %in% valid_sites2()))

      if (watsel == "NULL") {
        watsel <- NULL
      }
      if (mapsel == "NULL") {
        mapsel <- NULL
      }

      anlzMWRmap(res = fsetls()$res, param = param2, acc = fsetls()$acc, sit = fsetls()$sit, dtrng = dtrng2, site = sites2, addwater = watsel, maptype = mapsel, bssize = 18, warn = FALSE) +
        ggplot2::labs(title = NULL)
    })
  })
}

## To be copied in the UI
# mod_visualize_ui("visualize_1")

## To be copied in the server
# mod_visualize_server("visualize_1")
