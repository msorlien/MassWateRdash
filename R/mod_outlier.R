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
    page_sidebar(
      sidebar = sidebar(
        title = "Options",
        width = 500,
        uiOutput("prm1"),
        uiOutput("dtrng1"),
        selectInput("group1", "Group by", choices = c("month", "week", "site")),
        selectInput("type1", "Plot type", choices = c("box", "jitterbox", "jitter"))
      ),
      navset_card_underline(
        full_screen = T,
        nav_panel(
          "Plot",
          plotOutput("outlier_plot")
        ),
        nav_panel(
          "Table",
          reactable::reactableOutput("outlier_table")
        ),
        nav_panel(
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
mod_outlier_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns
    output$outlier_plot <- renderPlot({
      
      # inputs
      param1 <- input$param1
      dtrng1 <- as.character(input$dtrng1)
      group1 <- input$group1
      type1 <- input$type1
      
      req(fsetls()$res, fsetls()$acc, param1, dtrng1)
      
      anlzMWRoutlier(res = fsetls()$res, param = param1, acc = fsetls()$acc, group = group1, type = type1, dtrng = dtrng1, bssize = 18) + 
        ggplot2::labs(title = NULL)
      
    })
    
    output$outlier_table <- reactable::renderReactable({
      
      # inputs
      param1 <- input$param1
      dtrng1 <- as.character(input$dtrng1)
      group1 <- input$group1
      type1 <- input$type1
      
      req(fsetls()$res, fsetls()$acc, param1, dtrng1)
      
      tab <- anlzMWRoutlier(res = fsetls()$res, param = param1, acc = fsetls()$acc, group = group1, dtrng = dtrng1, outliers = T)
      
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
      filename = function(){'outlierreport.docx'},
      content = function(file){
        
        # inputs
        dtrng1 <- as.character(input$dtrng1)
        group1 <- input$group1
        type1 <- input$type1
        
        anlzMWRoutlierall(fset = fsetls(), group = group1, type = type1, dtrng = dtrng1, format = 'word', 
                          output_dir = dirname(file), 
                          output_file = basename(file))
        
      }
    )
    
    # download outlier report zip
    output$dwnldoutzip <- downloadHandler(
      filename = function(){'outlierreport.zip'},
      content = function(file){
        
        # inputs
        dtrng1 <- as.character(input$dtrng1)
        group1 <- input$group1
        type1 <- input$type1
        
        anlzMWRoutlierall(fset = fsetls(), group = group1, type = type1, dtrng = dtrng1, format = 'zip', 
                          output_dir = dirname(file), 
                          output_file = basename(file))
        
      }
    )
  })
}
    
## To be copied in the UI
# mod_outlier_ui("outlier_1")
    
## To be copied in the server
# mod_outlier_server("outlier_1")
