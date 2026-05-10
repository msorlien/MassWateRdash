source('R/global.R')

addResourcePath(
  prefix = "toimg", 
  directoryPath = "www"
)

# ui -----
ui <- page_navbar(
  header = tags$head(
    tags$script(HTML(
      "$(document).on('shown.bs.modal', function(e) {
        $(e.target).find('.rhandsontable').each(function() {
          var ht = HTMLWidgets.getInstance(this);
          if (ht && ht.hot) { ht.hot.render(); }
        });
      });"
    )),
    tags$style(HTML(
      ".rhandsontable .htCore thead th { white-space: nowrap; }
       .modal-dialog.modal-xl { max-width: 90vw; }
       .value-box-value { font-size: 1.5rem !important; }
       .fill-height { height: calc(100vh - 58px); overflow: hidden; }
       .card-scroll .card-body { overflow-y: auto; }
       .shiny-download-link:hover { filter: brightness(0.88); }"
    ))
  ),
  footer = tagList(
    tags$div(
      id    = "loading-indicator",
      style = "display: none; position: fixed; bottom: 15px; right: 15px; z-index: 9999;
               background: rgba(0,0,0,0.6); color: white; padding: 5px 12px;
               border-radius: 4px; font-size: 0.85em;",
      bs_icon("arrow-repeat"), " Loading..."),
    tags$style(
      "html.shiny-busy #loading-indicator { display: block !important; }")
  ),
  title = span(
    img(src = "toimg/logo.png", height = "40px", style = "margin-right: 10px;"),
    "MassWateR Dashboard"
  ),

  nav_panel(
    class = 'fill-height',
    title = "Overview",
    value = 'overview',
    navset_card_underline(
      full_screen = TRUE,
      height = '100%',
      nav_panel(
        title = '',
        class = 'card-scroll',
        shiny::includeMarkdown('www/overview.md')
      )
    )
  ),

  nav_panel("1 Upload & Validate",

    page_sidebar(

      sidebar = sidebar(
        title = "Upload Data Files",
        width = 500,
        div(style = "display: flex; align-items: center; gap: 12px;",
          div(style = "flex: 0 0 auto;", shinyWidgets::materialSwitch('tester', "Test mode", FALSE)),
          div(style = "flex: 1;", uiOutput("download_data_btn"))
        ),
        actionButton(
          "show_format_modal",
          "Convert from another format",
          icon = icon("right-left"),
          width = "100%",
          class = "btn-outline-secondary mb-3"
        ),
        fileInput("resdat", "Upload Results Data (.xlsx)", accept = ".xlsx"),
        fileInput("accdat", "Upload DQO Accuracy Data (.xlsx)", accept = ".xlsx"),
        fileInput("frecomdat", "Upload DQO Frequency & Completeness Data (.xlsx)", accept = ".xlsx"),
        fileInput("sitdat", "Upload Site Data (.xlsx)", accept = ".xlsx"),
        fileInput("wqxdat", "Upload WQX Meta Data (.xlsx)", accept = ".xlsx"),
        fileInput("censdat", "Upload Censored Data (.xlsx) (optional)", accept = ".xlsx")
      ),
      
      layout_columns(
        fill = FALSE,
        value_box(
          title = "Results Data",
          value = htmlOutput("resdat_status")
        ),
        value_box(
          title = "Accuracy Data",
          value = htmlOutput("accdat_status")
        ),
        value_box(
          title = "Frequency & Completeness Data",
          value = htmlOutput("frecomdat_status")
        ),
        value_box(
          title = "Sites Data",
          value = htmlOutput("sitdat_status")
        ),
        value_box(
          title = "WQX Data",
          value = htmlOutput("wqxdat_status")
        ),
        value_box(
          title = "Censored Data",
          value = htmlOutput("censdat_status")
        )
      ),
      
      card(
        card_header("Data Validation Messages"),
        uiOutput("validation_messages"),
        uiOutput("resdat_editor"),
        uiOutput("accdat_editor"),
        uiOutput("frecomdat_editor"),
        uiOutput("sitdat_editor"),
        uiOutput("wqxdat_editor"),
        uiOutput("censdat_editor")
      )

    )
            
  ),
  
  # Outlier assessment -----
  nav_panel("2 Outlier assessment",
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
  ),
  
  # QC reporting -----
  nav_panel("3 QC reporting",
    navset_card_underline(
      full_screen = T,
      nav_panel(
        "DQO tables", 
        navset_pill(
          nav_panel(
            "Frequency & Completeness",
            uiOutput("frecomdat_table")
          ),
          nav_panel(
            "Accuracy",
            uiOutput("accdat_table")
          )
        )
      ),
      nav_panel(
        "Accuracy",
        navset_pill(
          nav_panel(
            "Percent",
            uiOutput("tabaccper")
          ), 
          nav_panel(
            "Summary",
            uiOutput("tabaccsum")
          )
        )
      ),
      nav_panel(
        "Frequency",
        navset_pill(
          nav_panel(
            "Percent",
            uiOutput("tabfreper")
          ),
          nav_panel(
            "Summary",
            uiOutput("tabfresum")
          )
        )
      ),
      nav_panel(
        "Completeness",
        uiOutput("tabcom")
      ),
      nav_panel(
        "Raw Data",
        navset_pill(
          nav_panel(
            "Field Duplicates",
            uiOutput("indflddup")
          ),
          nav_panel(
            "Lab Duplicates",
            uiOutput("indlabdup")
          ),
          nav_panel(
            "Field Blanks",
            uiOutput("indfldblk")
          ),
          nav_panel(
            "Lab Blanks",
            uiOutput("indlabblk")
          ),
          nav_panel(
            "Lab Spikes / Instrument Checks",
            uiOutput("indlabins")
          )
        )
      ),
      nav_panel(
        "Report",
        uiOutput("dwnldqcbutt")
      )
    )
  ),
  
  # WQX output -----
  nav_panel("4 WQX output",
    navset_card_underline(
      full_screen = T,
      nav_panel(
        "Projects", 
        reactable::reactableOutput('tabwqxprojects')
      ),
      nav_panel(
        "Locations",
        reactable::reactableOutput('tabwqxlocations')
      ),
      nav_panel(
        "Results",
        reactable::reactableOutput('tabwqxresults')
      ),
      nav_panel(
        "Workbook", 
        uiOutput("dwnldwqxbutt")
      )
    )
  ),
  
  # Visualize -----
  nav_panel("5 Visualize",
            
    page_sidebar(
      sidebar = sidebar(
        title = "Plot options",
        width = 500,
        uiOutput("prm2"),
        uiOutput("dtrng2"),
        uiOutput("sites2"),
        uiOutput("notmap"),
        uiOutput("vizui"),
        uiOutput("confint_ui")
      ),
      
      navset_card_underline(
        full_screen = T,
        id = "viz_selected",
        nav_panel(
          "Season",
          plotOutput("season_plot")
        ),
        nav_panel(
          "Date",
          plotOutput("date_plot")
        ),
        nav_panel(
          "Site",
          plotOutput("site_plot")
        ),
        nav_panel(
          "Map",
          selectInput('watsel', 'Water feature detail', choices = c('low', 'medium', 'high', "none" = 'NULL')),
          selectInput('mapsel', 'Basemap selection', choices = c("none" = 'NULL', "OpenStreetMap", "OpenStreetMap.DE", "OpenStreetMap.France", "OpenStreetMap.HOT", "OpenTopoMap", "Esri.WorldStreetMap", "Esri.DeLorme", "Esri.WorldTopoMap", "Esri.WorldImagery", "Esri.WorldTerrain", "Esri.WorldShadedRelief", "Esri.OceanBasemap", "Esri.NatGeoWorldMap", "Esri.WorldGrayCanvas", "CartoDB.Positron", "CartoDB.PositronNoLabels", "CartoDB.PositronOnlyLabels", "CartoDB.DarkMatter", "CartoDB.DarkMatterNoLabels", "CartoDB.DarkMatterOnlyLabels", "CartoDB.Voyager", "CartoDB.VoyagerNoLabels", "CartoDB.VoyagerOnlyLabels")),
          plotOutput("map_plot")
        )
      )
      
    )
            
  ),
  
  nav_spacer(),
  
  nav_item(
    tags$a(
      href = "https://github.com/massbays-tech/MassWateRdash",
      target = "_blank",
      "Source Code"
    )
  )
  
)

# server -----
server <- function(input, output, session) {
  
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
  
  output$prm2 <- renderUI({
    
    # inputs
    fset <- fsetls()
    
    validate(
      need(!is.null(fset$res), 'Waiting for input data...')
    )
    
    tosel <- sort(unique(fset$res$`Characteristic Name`))
    
    selectInput("param2", "Parameter", choices = tosel)
    
  })
  
  output$dtrng1 <- renderUI({
    
    # inputs
    param1 <- input$param1

    req(fsetls()$res, param1)

    tosel <- fsetls()$res |> 
      dplyr::filter(`Characteristic Name` == param1) |> 
      dplyr::pull(`Activity Start Date`) |> 
      range() |> 
      as.Date()
    
    sliderInput("dtrng1", "Date range", min = tosel[1], max = tosel[2], value = tosel, width = '95%')
    
  })
  
  output$dtrng2 <- renderUI({
    
    # inputs
    param2 <- input$param2
    
    req(fsetls()$res, param2)
    
    tosel <- fsetls()$res |> 
      dplyr::filter(`Characteristic Name` == param2) |> 
      dplyr::pull(`Activity Start Date`) |> 
      range() |> 
      as.Date()
    
    sliderInput("dtrng2", "Date range", min = tosel[1], max = tosel[2], value = tosel, width = '95%')
    
  })
  
  output$sites2 <- renderUI({
    
    # inputs
    param2 <- input$param2
    dtrng2 <- input$dtrng2
    
    req(fsetls()$res, param2, dtrng2)

    tosel <- fsetls()$res |> 
      dplyr::filter(`Characteristic Name` == param2) |> 
      dplyr::filter(`Activity Start Date` >= dtrng2[1] & `Activity Start Date` <= dtrng2[2]) |> 
      dplyr::pull(`Monitoring Location ID`) |> 
      unique() |> 
      sort()
    
    selectInput("sites2", "Select sites", choices = tosel, selected = tosel, selectize = T, multiple = T)
    
  })
  
  output$notmap <- renderUI({

    if(input$viz_selected != 'Map')
      selectInput("thresh", "Treshold type", choices = c('fresh', 'marine', 'none'))

  })

  output$vizui <- renderUI({
    
    out <- NULL
    
    if(input$viz_selected %in% c('Season', 'Site'))
      out <- selectInput("type2", "Plot type", choices = c("box", "jitterbox", "bar", "jitterbar", "jitter"))
    
    if(input$viz_selected == 'Date')
      out <- selectInput("group2", "Plot grouping", choices = c("site", "locgroup", "all"))

    return(out)

  })

  output$confint_ui <- renderUI({

    viz <- input$viz_selected

    show <- if(viz %in% c('Season', 'Site')) {
      isTRUE(input$type2 %in% c('bar', 'jitterbar'))
    } else if(viz == 'Date') {
      isTRUE(input$group2 %in% c('locgroup', 'all'))
    } else {
      FALSE
    }

    if(show)
      selectInput("confint2", "Show confidence", choices = c(F, T))

  })

  output$dwnldoutwrdbutt <- renderUI({
    
    req(fsetls()$res, fsetls()$acc) 
    
    dl_btn('dwnldoutwrd', 'Download outlier report: Word')
    
  })
  
  output$dwnldoutzipbutt <- renderUI({
    
    req(fsetls()$res, fsetls()$acc)
    
    dl_btn('dwnldoutzip', 'Download outlier report: Zipped images')
    
  })
  
  output$dwnldqcbutt <- renderUI({
    
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)  
    
    dl_btn('dwnldqc', 'Download quality control report')
    
  })
  
  output$dwnldwqxbutt <- renderUI({
    
    req(req(fsetls()$res, fsetls()$acc, fsetls()$sit, fsetls()$wqx)) 
    
    dl_btn('dwnldwqx', 'Download WQX workbook')
    
  })
  
  # Modules ----
  wqf <- mod_format_server("prep")

  observeEvent(wqf$dat_results(), {
    req(wqf$dat_results())
    from_format_upload(wqf$dat_results(), retry_fns$resdat, "resdat")
    showNotification("Results data loaded from format converter", type = "message", duration = 4)
  })

  observeEvent(wqf$dat_sites(), {
    req(wqf$dat_sites())
    from_format_upload(wqf$dat_sites(), retry_fns$sitdat, "sitdat")
    showNotification("Sites data loaded from format converter", type = "message", duration = 4)
  })

  observeEvent(input$show_format_modal, {
    showModal(modalDialog(
      title = "Convert from Another Format",
      mod_format_ui("prep", in_modal = TRUE),
      size = "xl",
      footer = modalButton("Close"),
      easyClose = TRUE
    ))
  })

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
  observeEvent(input$resdat, {
    fl_upload(input$resdat, readMWRresults, "resdat")
  })
  
  observeEvent(input$accdat, {
    fl_upload(input$accdat, readMWRacc, "accdat")
  })
  
  observeEvent(input$frecomdat, {
    fl_upload(input$frecomdat, readMWRfrecom, "frecomdat")
  })
  
  observeEvent(input$sitdat, {
    fl_upload(input$sitdat, readMWRsites, "sitdat")
  })
  
  observeEvent(input$wqxdat, {
   fl_upload(input$wqxdat, readMWRwqx, "wqxdat")
  })

  observeEvent(input$censdat, {
    fl_upload(input$censdat, readMWRcens, "censdat")
  })
  
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
    if (!any_loaded) return(NULL)
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
        if (!is.null(df))
          write.csv(df, file.path(tmp_dir, nm), row.names = FALSE)
      }
      old_wd <- setwd(tmp_dir)
      on.exit(setwd(old_wd), add = TRUE)
      utils::zip(file, list.files(tmp_dir))
    }
  )

  # Output validation messages
  output$validation_messages <- renderUI({
    msg <- validation_log()
    if (nchar(trimws(msg)) == 0) return(NULL)
    msg <- gsub("\033\\[[0-9;]*[mGKHFABCDJK]", "", msg)  # strip ANSI codes
    lines <- strsplit(msg, "\n")[[1]]
    lines <- lines[nchar(trimws(lines)) > 0]
    div(HTML(paste(lines, collapse = "<br>")))
  })

  # In-app data editors - shown when a file fails validation
  file_defs <- list(
    list(name = "resdat",    label = "Results Data"),
    list(name = "accdat",    label = "DQO Accuracy Data"),
    list(name = "frecomdat", label = "DQO Frequency & Completeness Data"),
    list(name = "sitdat",    label = "Site Data"),
    list(name = "wqxdat",    label = "WQX Meta Data"),
    list(name = "censdat", label = "Censored Data")
  )

  for (fd in file_defs) {
    local({
      nm  <- fd$name
      lbl <- fd$label

      # Button shown inside the validation card when file has a validation error
      output[[paste0(nm, "_editor")]] <- renderUI({
        req(isTRUE(edit_visible[[nm]]))
        actionButton(paste0(nm, "_open_editor"), paste("Edit", lbl),
                     class = "btn-warning", icon = icon("pencil"))
      })

      # Build modal with only the relevant card (no display:none needed)
      build_modal <- function(col_err) {
        modalDialog(
          title = paste("Edit", lbl, "— Fix Validation Errors"),
          size = "xl",
          easyClose = FALSE,
          uiOutput(paste0(nm, "_modal_msgs")),
          br(),
          p("Fix the issue below, then click 'Try upload again'."),
          if (col_err)
            card(
              card_header("Column Names"),
              rHandsontableOutput(paste0(nm, "_hot_headers"))
            )
          else
            card(
              card_header(
                div(
                  class = "d-flex justify-content-between align-items-center w-100",
                  "Data",
                  uiOutput(paste0(nm, "_row_filter_ui"))
                )
              ),
              rHandsontableOutput(paste0(nm, "_hot"))
            ),
          footer = tagList(
            actionButton(paste0(nm, "_retry"), "Try upload again", class = "btn-primary"),
            modalButton("Close")
          )
        )
      }

      observeEvent(input[[paste0(nm, "_open_editor")]], {
        showModal(build_modal(is_column_error(validation_log())))
      })

      # Validation message shown inside the modal
      output[[paste0(nm, "_modal_msgs")]] <- renderUI({
        msg <- validation_log()
        if (nchar(trimws(msg)) == 0) return(NULL)
        msg <- gsub("\033\\[[0-9;]*[mGKHFABCDJK]", "", msg)
        lines <- strsplit(msg, "\n")[[1]]
        lines <- lines[nchar(trimws(lines)) > 0]
        div(HTML(paste(lines, collapse = "<br>")))
      })
      outputOptions(output, paste0(nm, "_modal_msgs"), suspendWhenHidden = FALSE)

      # Column names editor (renders even when modal is closed so it's ready on open)
      output[[paste0(nm, "_hot_headers")]] <- renderRHandsontable({
        req(raw_data_states[[nm]])
        col_names <- names(raw_data_states[[nm]])
        locs <- parse_error_locations(validation_log())
        header_df <- setNames(
          as.data.frame(as.list(col_names), stringsAsFactors = FALSE),
          as.character(seq_along(col_names))
        )
        hot <- rhandsontable(header_df, width = "100%", height = 75, rowHeaders = FALSE) |>
          hot_table(wordWrap = FALSE)
        for (idx in locs$col_indices) {
          if (idx >= 1 && idx <= length(col_names))
            hot <- hot |> hot_col(idx, renderer = "
              function(instance, td, row, col, prop, value, cellProperties) {
                Handsontable.renderers.TextRenderer.apply(this, arguments);
                td.style.background = '#f8d7da';
                td.style.fontWeight = 'bold';
              }
            ")
        }
        hot
      })
      outputOptions(output, paste0(nm, "_hot_headers"), suspendWhenHidden = FALSE)

      # Row filter toggle — shown in the Data card header when problem rows exist
      output[[paste0(nm, "_row_filter_ui")]] <- renderUI({
        problem_rows <- parse_problem_rows(validation_log())
        if (length(problem_rows) == 0) return(NULL)
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
      outputOptions(output, paste0(nm, "_row_filter_ui"), suspendWhenHidden = FALSE)

      # Data editor — shows only problem rows by default when they exist
      output[[paste0(nm, "_hot")]] <- renderRHandsontable({
        req(raw_data_states[[nm]])
        dat <- raw_data_states[[nm]]
        problem_rows <- parse_problem_rows(validation_log())
        locs <- parse_error_locations(validation_log(), names(dat))
        show_all <- isTRUE(input[[paste0(nm, "_show_all_rows")]])
        if (length(problem_rows) > 0 && !show_all) {
          valid_rows <- problem_rows[problem_rows >= 1 & problem_rows <= nrow(dat)]
          dat <- dat[valid_rows, , drop = FALSE]
        }
        hot <- rhandsontable(dat, width = "100%", height = 450) |>
          hot_table(wordWrap = FALSE)
        col_names <- names(dat)
        if (length(problem_rows) > 0 || length(locs$cell_map) > 0) {
          for (i in seq_along(col_names)) {
            cn <- col_names[i]
            col_bad <- locs$cell_map[[cn]]
            cell_0 <- if (!is.null(col_bad)) {
              if (!show_all && length(problem_rows) > 0)
                which(problem_rows %in% col_bad) - 1L
              else
                col_bad - 1L
            } else integer(0)
            row_0 <- if (show_all && length(problem_rows) > 0) problem_rows - 1L else integer(0)
            if (length(row_0) == 0 && length(cell_0) == 0) next
            hot <- hot |> hot_col(i, renderer = sprintf(
              "function(instance, td, row, col, prop, value, cellProperties) {
                 Handsontable.renderers.TextRenderer.apply(this, arguments);
                 if ([%s].indexOf(row) > -1) { td.style.background = '#fff3cd'; }
                 if ([%s].indexOf(row) > -1) { td.style.background = '#ffc107'; }
               }",
              paste(row_0, collapse = ","),
              paste(cell_0, collapse = ",")
            ))
          }
        }
        hot
      })
      outputOptions(output, paste0(nm, "_hot"), suspendWhenHidden = FALSE)

      observeEvent(input[[paste0(nm, "_retry")]], {
        col_err <- is_column_error(validation_log())
        handle_retry(
          nm,
          hot_input         = if (!col_err) input[[paste0(nm, "_hot")]] else NULL,
          hot_headers_input = if (col_err)  input[[paste0(nm, "_hot_headers")]] else NULL,
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
      })
    })
  }

  # data inputs
  fsetls <- reactive({
    
    if(!input$tester){
        resdat <- data_states$resdat
        accdat <- data_states$accdat
        frecomdat <- data_states$frecomdat
        sitdat <- data_states$sitdat
        wqxdat <- data_states$wqxdat
        censdat <- data_states$censdat
    }

    if(input$tester == T){
      resdat <- readMWRresults(system.file("extdata", "ExampleResults.xlsx", package = "MassWateR"), runchk = F)
      accdat <- readMWRacc(system.file("extdata", "ExampleDQOAccuracy.xlsx", package = "MassWateR"), runchk = F)
      frecomdat <- readMWRfrecom(system.file("extdata", "ExampleDQOFrequencyCompleteness.xlsx", package = "MassWateR"), runchk = F)
      sitdat <- readMWRsites(system.file("extdata", "ExampleSites.xlsx", package = "MassWateR"), runchk = F)
      wqxdat <- readMWRwqx(system.file("extdata", "ExampleWQX.xlsx", package = "MassWateR"), runchk = F)
      censdat <- readMWRcens(system.file("extdata", "ExampleCensored.xlsx", package = "MassWateR"), runchk = F)
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
  
  # Outlier assessment -----
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
  
  # QC reporting -----
  
  # dqo table frecomdat
  output$frecomdat_table <- renderUI({
    
    req(fsetls()$frecom)
    
    frecomdat_tab(fsetls()$frecom, dqofontsize, padding, wd)
    
  })
  
  # dqo table accdat
  output$accdat_table <- renderUI({
    
    req(fsetls()$acc)
    
    accdat_tab(fsetls()$acc, dqofontsize, padding, wd)
    
  })
  
  # frequency table percent
  output$tabfreper <- renderUI({
    
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)
    
    tabMWRfre(res = fsetls()$res, acc = fsetls()$acc, frecom = fsetls()$frecom, type = 'percent', warn = F) |>
      thmsum(wd = wd) |> 
      flextable::htmltools_value()
    
  })
  
  # frequency summary table
  output$tabfresum <- renderUI({
    
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)
    
    tabMWRfre(res = fsetls()$res, acc = fsetls()$acc, frecom = fsetls()$frecom, type = 'summary', warn = F) |>
      thmsum(wd = wd) |> 
      flextable::htmltools_value()
    
  })
  
  # accuracy table percent
  output$tabaccper <- renderUI({
    
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)
    
    tabMWRacc(res = fsetls()$res, acc = fsetls()$acc, frecom = fsetls()$frecom, type = 'percent', warn = F) |>
      thmsum(wd = wd) |> 
      flextable::htmltools_value()
    
  })
  
  # accuracy table summary
  output$tabaccsum <- renderUI({
    
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)
    
    tabMWRacc(res = fsetls()$res, acc = fsetls()$acc, frecom = fsetls()$frecom, type = 'summary', warn = F) |>
      thmsum(wd = wd) |> 
      flextable::htmltools_value()
    
  })
  
  # completeness table
  output$tabcom <- renderUI({
    
    req(fsetls()$res, fsetls()$frecom)
    
    out <- tabMWRcom(res = fsetls()$res, frecom = fsetls()$frecom, cens = fsetls()$cens, warn = F, parameterwd = 1.15)
    out <- out |> 
      flextable::width(width = (wd - 3.15) / (flextable::ncol_keys(out) - 2), j = 2:(flextable::ncol_keys(out) - 1)) |>
      flextable::htmltools_value()
    
    return(out)
    
  })
  
  # individual field duplicates
  output$indflddup <- renderUI({
    
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)
    
    tabMWRacc(res = fsetls()$res, acc = fsetls()$acc, frecom = fsetls()$frecom, type = 'individual', accchk = 'Field Duplicates', warn = F, caption = F) |> 
      thmsum(wd = wd) |> 
      flextable::htmltools_value()
    
  })
  
  # individual lab duplicates
  output$indlabdup <- renderUI({
    
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)
    
    tabMWRacc(res = fsetls()$res, acc = fsetls()$acc, frecom = fsetls()$frecom, type = 'individual', accchk = 'Lab Duplicates', warn = F, caption = F) |> 
      thmsum(wd = wd) |> 
      flextable::htmltools_value()
    
  })
  
  # individual field blanks
  output$indfldblk <- renderUI({
    
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)
    
    tabMWRacc(res = fsetls()$res, acc = fsetls()$acc, frecom = fsetls()$frecom, type = 'individual', accchk = 'Field Blanks', warn = F, caption = F) |> 
      thmsum(wd = wd) |> 
      flextable::htmltools_value()
    
  })
  
  # individual lab blanks
  output$indlabblk <- renderUI({
    
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)
    
    tabMWRacc(res = fsetls()$res, acc = fsetls()$acc, frecom = fsetls()$frecom, type = 'individual', accchk = 'Lab Blanks', warn = F, caption = F) |> 
      thmsum(wd = wd) |> 
      flextable::htmltools_value()
    
  })
  
  # individual lab spikes/instrument checks
  output$indlabins <- renderUI({
    
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)
    
    tabMWRacc(res = fsetls()$res, acc = fsetls()$acc, frecom = fsetls()$frecom, type = 'individual', accchk = 'Lab Spikes / Instrument Checks', warn = F, caption = F) |> 
      thmsum(wd = wd) |> 
      flextable::htmltools_value()
    
  })
  
  # download qc report word
  output$dwnldqc <- downloadHandler(
    filename = function(){'qcreport.docx'},
    content = function(file){
      
      qcMWRreview(fset = fsetls(), 
                  output_dir = dirname(file), 
                  output_file = basename(file))
      
    }
  )
  
  # WQX -----
  
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
    filename = function(){'wqxtab.xlsx'},
    content = function(file){
      
      tabMWRwqx(fset = fsetls(), 
                  output_dir = dirname(file), 
                  output_file = basename(file))
      
    }
  )
  
  # Visualize ----
  output$season_plot <- renderPlot({
    
    # inputs
    thresh <- input$thresh
    param2 <- input$param2
    dtrng2 <- as.character(input$dtrng2)
    sites2 <- input$sites2
    type2 <- input$type2
    confint2 <- isTRUE(as.logical(input$confint2))
    
    req(fsetls()$res, fsetls()$acc, param2, dtrng2, sites2)

    anlzMWRseason(res = fsetls()$res, param = param2, acc = fsetls()$acc, sit = fsetls()$sit, thresh = thresh, type = type2, dtrng = dtrng2, site = sites2, confint = confint2, bssize = 18) + 
      ggplot2::labs(title = NULL)
    
  })
  
  output$date_plot <- renderPlot({
    
    # inputs
    thresh <- input$thresh
    param2 <- input$param2
    dtrng2 <- as.character(input$dtrng2)
    sites2 <- input$sites2
    group2 <- input$group2
    confint2 <- isTRUE(as.logical(input$confint2))
    
    req(fsetls()$res, fsetls()$acc, param2, dtrng2, sites2)
    
    anlzMWRdate(res = fsetls()$res, param = param2, acc = fsetls()$acc, sit = fsetls()$sit, thresh = thresh, group = group2, dtrng = dtrng2, site = sites2, confint = confint2, bssize = 18) + 
      ggplot2::labs(title = NULL)
    
  })
  
  output$site_plot <- renderPlot({
    
    # inputs
    thresh <- input$thresh
    param2 <- input$param2
    dtrng2 <- as.character(input$dtrng2)
    sites2 <- input$sites2
    type2 <- input$type2
    confint2 <- isTRUE(as.logical(input$confint2))
    
    req(fsetls()$res, fsetls()$acc, param2, dtrng2, sites2)
    
    anlzMWRsite(res = fsetls()$res, param = param2, acc = fsetls()$acc, sit = fsetls()$sit, thresh = thresh, type = type2, dtrng = dtrng2, site = sites2, confint = confint2, bssize = 18) + 
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
    
    if(watsel == 'NULL')
      watsel <- NULL
    if(mapsel == 'NULL')
      mapsel <- NULL
    
    anlzMWRmap(res = fsetls()$res, param = param2, acc = fsetls()$acc, sit = fsetls()$sit, dtrng = dtrng2, site = sites2, addwater = watsel, maptype = mapsel, bssize = 18) + 
      ggplot2::labs(title = NULL)
    
  })
  
}

shinyApp(ui = ui, server = server)