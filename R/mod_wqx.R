#' wqx UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_wqx_ui <- function(id) {
  ns <- NS(id)
  tagList(
    bslib::navset_card_underline(
      full_screen = T,
      bslib::nav_panel(
        "Projects",
        reactable::reactableOutput("tabwqxprojects")
      ),
      bslib::nav_panel(
        "Locations",
        reactable::reactableOutput("tabwqxlocations")
      ),
      bslib::nav_panel(
        "Results",
        reactable::reactableOutput("tabwqxresults")
      ),
      bslib::nav_panel(
        "Workbook",
        uiOutput("dwnldwqxbutt")
      )
    )
  )
}

#' wqx Server Functions
#'
#' @noRd
mod_wqx_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    # list output
    tabwqx <- reactive({
      req(fsetls()$res, fsetls()$acc, fsetls()$sit, fsetls()$wqx)

      tabMWRwqx(fset = fsetls(), listout = T, warn = F)
    })

    # projects table
    output$tabwqxprojects <- reactable::renderReactable({
      req(tabwqx())

      reactable::reactable(
        tabwqx()$Projects,
        defaultColDef = reactable::colDef(
          resizable = TRUE
        ),
        filterable = T
      )
    })

    # locations table
    output$tabwqxlocations <- reactable::renderReactable({
      req(tabwqx())

      reactable::reactable(
        tabwqx()$Locations,
        defaultColDef = reactable::colDef(
          resizable = TRUE
        ),
        filterable = T
      )
    })

    # results table
    output$tabwqxresults <- reactable::renderReactable({
      req(tabwqx())

      reactable::reactable(
        tabwqx()$Results,
        defaultColDef = reactable::colDef(
          resizable = TRUE
        ),
        filterable = T
      )
    })

    # download wqx workbook
    output$dwnldwqx <- downloadHandler(
      filename = function() {
        "wqxtab.xlsx"
      },
      content = function(file) {
        tabMWRwqx(
          fset = fsetls(),
          output_dir = dirname(file),
          output_file = basename(file)
        )
      }
    )
  })
}

## To be copied in the UI
# mod_wqx_ui("wqx_1")

## To be copied in the server
# mod_wqx_server("wqx_1")
