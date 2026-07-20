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
       .shiny-download-link:hover { filter: brightness(0.88); }
       #show_format_modal:hover, #open_plot_download:hover { filter: brightness(0.88); }
       :root { --bs-primary: #00A4CF; --bs-primary-rgb: 0, 164, 207; }
       .progress-bar { background-color: #00A4CF !important; }
       .nav-pills .nav-link.active { background-color: #00A4CF !important; }
       .bootstrap-select > .dropdown-toggle { background-color: #fff !important; border: 1px solid #6c757d !important; color: #212529 !important; box-shadow: none !important; padding: 0.375rem 0.75rem !important; line-height: 1.5 !important; font-size: 1rem !important; }
       .bootstrap-select > .dropdown-toggle:hover { background-color: #fff !important; border-color: #6c757d !important; box-shadow: none !important; }
       .bootstrap-select > .dropdown-toggle:focus, .bootstrap-select.show > .dropdown-toggle { background-color: #fff !important; border-color: #86b7fe !important; box-shadow: 0 0 0 0.25rem rgba(13,110,253,.25) !important; }
       .bootstrap-select .filter-option-inner-inner { font-size: 0.875rem !important; }
       .bootstrap-select .dropdown-menu .dropdown-item { font-size: 0.875rem !important; }
       .bootstrap-select .dropdown-menu.inner li.selected a,
       .bootstrap-select .dropdown-menu.inner li.selected a:hover,
       .bootstrap-select .dropdown-menu .dropdown-item.active,
       .bootstrap-select .dropdown-menu .dropdown-item:active { background-color: #00A4CF !important; color: white !important; }
       .bs-actionsbox .btn-group { display: flex !important; gap: 6px; }
       .bs-actionsbox .btn { background-color: #00A4CF !important; border-color: #00A4CF !important; color: white !important; border-radius: 4px !important; flex: 1; }
       .shiny-notification-message { background-color: #00A4CF !important; color: white !important; border-color: #00A4CF !important; }
       .irs--shiny .irs-bar { background: #00A4CF !important; border-top-color: #00A4CF !important; border-bottom-color: #00A4CF !important; }
       .irs--shiny .irs-bar--single { border-left-color: #00A4CF !important; }
       .irs--shiny .irs-handle { border-color: #00A4CF !important; background-color: #00A4CF !important; }
       .irs--shiny .irs-handle > i:first-child { background-color: #00A4CF !important; }
       .irs--shiny .irs-handle.state_hover, .irs--shiny .irs-handle:hover { background-color: #00A4CF !important; }
       .irs--shiny .irs-from, .irs--shiny .irs-to, .irs--shiny .irs-single { background-color: #00A4CF !important; }"
    ))
  ),
  footer = tagList(
    tags$div(
      id = "loading-indicator",
      style = "display: none; position: fixed; bottom: 15px; right: 15px; z-index: 9999;
               background: rgba(0,0,0,0.6); color: white; padding: 5px 12px;
               border-radius: 4px; font-size: 0.85em;",
      bs_icon("arrow-repeat"),
      " Loading..."
    ),
    tags$style(
      "html.shiny-busy #loading-indicator { display: block !important; }"
    )
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

  # Upload & Validate----
  nav_panel(
    "1 Upload & Validate",
    mod_upload("upload")
  ),

  # Outlier assessment -----
  nav_panel(
    "2 Outlier assessment",
    page_sidebar(
      sidebar = sidebar(
        title = "Options",
        width = 500,
        uiOutput("prm1"),
        uiOutput("dtrng1"),
        selectInput("group1", "Group by", choices = c("month", "week", "site")),
        selectInput(
          "type1",
          "Plot type",
          choices = c("box", "jitterbox", "jitter")
        )
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
  nav_panel(
    "3 QC reporting",
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
  nav_panel(
    "4 WQX output",
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
  nav_panel(
    "5 Visualize",

    page_sidebar(
      sidebar = sidebar(
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
          selectInput(
            'watsel',
            'Water feature detail',
            choices = c('low', 'medium', 'high', "none" = 'NULL')
          ),
          selectInput(
            'mapsel',
            'Basemap selection',
            choices = c(
              "none" = 'NULL',
              "OpenStreetMap",
              "OpenStreetMap.DE",
              "OpenStreetMap.France",
              "OpenStreetMap.HOT",
              "OpenTopoMap",
              "Esri.WorldStreetMap",
              "Esri.DeLorme",
              "Esri.WorldTopoMap",
              "Esri.WorldImagery",
              "Esri.WorldTerrain",
              "Esri.WorldShadedRelief",
              "Esri.OceanBasemap",
              "Esri.NatGeoWorldMap",
              "Esri.WorldGrayCanvas",
              "CartoDB.Positron",
              "CartoDB.PositronNoLabels",
              "CartoDB.PositronOnlyLabels",
              "CartoDB.DarkMatter",
              "CartoDB.DarkMatterNoLabels",
              "CartoDB.DarkMatterOnlyLabels",
              "CartoDB.Voyager",
              "CartoDB.VoyagerNoLabels",
              "CartoDB.VoyagerOnlyLabels"
            )
          ),
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
  # Modules
  fsetls <- mod_upload_server("upload")

  # reactive UI -----

  output$prm2 <- renderUI({
    # inputs
    fset <- fsetls()

    validate(
      need(!is.null(fset$res), 'Waiting for input data...')
    )

    tosel <- sort(unique(fset$res$`Characteristic Name`))

    selectInput("param2", "Parameter", choices = tosel)
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

    sliderInput(
      "dtrng2",
      "Date range",
      min = tosel[1],
      max = tosel[2],
      value = tosel,
      width = '95%'
    )
  })

  # Reactive: valid sites for the current param2 + date range.
  # Shared by output$sites2 (to populate choices) and the plot guards
  # (to block rendering when input$sites2 is still stale after a param change).
  valid_sites2 <- reactive({
    param2 <- input$param2
    dtrng2 <- input$dtrng2
    req(fsetls()$res, param2, dtrng2)
    fsetls()$res |>
      dplyr::filter(`Characteristic Name` == param2) |>
      dplyr::filter(
        `Activity Start Date` >= dtrng2[1] & `Activity Start Date` <= dtrng2[2]
      ) |>
      dplyr::pull(`Monitoring Location ID`) |>
      unique()
  })

  output$sites2 <- renderUI({
    dropdown("sites2", "Select sites", choices = valid_sites2())
  })

  output$notmap <- renderUI({
    if (input$viz_selected == 'Map') {
      return(NULL)
    }

    param2 <- input$param2
    req(param2)

    # Characteristic Name in the results file == Simple Parameter in thresholdMWR,
    # so filter directly without going through paramsMWR
    thresh_rows <- thresholdMWR |>
      dplyr::filter(`Simple Parameter` == param2)

    has_fresh <- nrow(thresh_rows) > 0 &&
      any(!is.na(thresh_rows$Fresh_1) | !is.na(thresh_rows$Fresh_2))
    has_marine <- nrow(thresh_rows) > 0 &&
      any(!is.na(thresh_rows$Marine_1) | !is.na(thresh_rows$Marine_2))

    # Hide entirely when no thresholds exist for this parameter
    if (!has_fresh && !has_marine) {
      return(NULL)
    }

    choices <- c(
      if (has_fresh) 'fresh',
      if (has_marine) 'marine',
      'none'
    )

    selectInput("thresh", "Threshold type", choices = choices)
  })

  output$vizui <- renderUI({
    out <- NULL

    if (input$viz_selected %in% c('Season', 'Site')) {
      out <- selectInput(
        "type2",
        "Plot type",
        choices = c("box", "jitterbox", "bar", "jitterbar", "jitter")
      )
    }

    if (input$viz_selected == 'Date') {
      out <- selectInput(
        "group2",
        "Plot grouping",
        choices = c("site", "locgroup", "all")
      )
    }

    return(out)
  })

  output$confint_ui <- renderUI({
    viz <- input$viz_selected

    show <- if (viz %in% c('Season', 'Site')) {
      isTRUE(input$type2 %in% c('bar', 'jitterbar'))
    } else if (viz == 'Date') {
      isTRUE(input$group2 %in% c('locgroup', 'all'))
    } else {
      FALSE
    }

    if (show) {
      selectInput("confint2", "Show confidence", choices = c(F, T))
    }
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
  wqf <- mod_upload_format_server("prep")

  observeEvent(wqf$dat_results(), {
    req(wqf$dat_results())
    from_format_upload(wqf$dat_results(), retry_fns$resdat, "resdat")
    showNotification(
      "Results data loaded from format converter",
      type = "message",
      duration = 4
    )
  })

  observeEvent(wqf$dat_sites(), {
    req(wqf$dat_sites())
    from_format_upload(wqf$dat_sites(), retry_fns$sitdat, "sitdat")
    showNotification(
      "Sites data loaded from format converter",
      type = "message",
      duration = 4
    )
  })

  observeEvent(input$show_format_modal, {
    showModal(modalDialog(
      title = "Convert from Another Format",
      mod_upload_format_ui("prep", in_modal = TRUE),
      size = "xl",
      footer = modalButton("Close"),
      easyClose = TRUE
    ))
  })

  # Outlier assessment -----
  output$outlier_plot <- renderPlot({
    # inputs
    param1 <- input$param1
    dtrng1 <- as.character(input$dtrng1)
    group1 <- input$group1
    type1 <- input$type1

    req(fsetls()$res, fsetls()$acc, param1, dtrng1)

    anlzMWRoutlier(
      res = fsetls()$res,
      param = param1,
      acc = fsetls()$acc,
      group = group1,
      type = type1,
      dtrng = dtrng1,
      bssize = 18
    ) +
      ggplot2::labs(title = NULL)
  })

  output$outlier_table <- reactable::renderReactable({
    # inputs
    param1 <- input$param1
    dtrng1 <- as.character(input$dtrng1)
    group1 <- input$group1
    type1 <- input$type1

    req(fsetls()$res, fsetls()$acc, param1, dtrng1)

    tab <- anlzMWRoutlier(
      res = fsetls()$res,
      param = param1,
      acc = fsetls()$acc,
      group = group1,
      dtrng = dtrng1,
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
      'outlierreport.docx'
    },
    content = function(file) {
      # inputs
      dtrng1 <- as.character(input$dtrng1)
      group1 <- input$group1
      type1 <- input$type1

      anlzMWRoutlierall(
        fset = fsetls(),
        group = group1,
        type = type1,
        dtrng = dtrng1,
        format = 'word',
        output_dir = dirname(file),
        output_file = basename(file)
      )
    }
  )

  # download outlier report zip
  output$dwnldoutzip <- downloadHandler(
    filename = function() {
      'outlierreport.zip'
    },
    content = function(file) {
      # inputs
      dtrng1 <- as.character(input$dtrng1)
      group1 <- input$group1
      type1 <- input$type1

      anlzMWRoutlierall(
        fset = fsetls(),
        group = group1,
        type = type1,
        dtrng = dtrng1,
        format = 'zip',
        output_dir = dirname(file),
        output_file = basename(file)
      )
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

    tabMWRfre(
      res = fsetls()$res,
      acc = fsetls()$acc,
      frecom = fsetls()$frecom,
      type = 'percent',
      warn = F
    ) |>
      thmsum(wd = wd) |>
      flextable::htmltools_value()
  })

  # frequency summary table
  output$tabfresum <- renderUI({
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)

    tabMWRfre(
      res = fsetls()$res,
      acc = fsetls()$acc,
      frecom = fsetls()$frecom,
      type = 'summary',
      warn = F
    ) |>
      thmsum(wd = wd) |>
      flextable::htmltools_value()
  })

  # accuracy table percent
  output$tabaccper <- renderUI({
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)

    tabMWRacc(
      res = fsetls()$res,
      acc = fsetls()$acc,
      frecom = fsetls()$frecom,
      type = 'percent',
      warn = F
    ) |>
      thmsum(wd = wd) |>
      flextable::htmltools_value()
  })

  # accuracy table summary
  output$tabaccsum <- renderUI({
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)

    tabMWRacc(
      res = fsetls()$res,
      acc = fsetls()$acc,
      frecom = fsetls()$frecom,
      type = 'summary',
      warn = F
    ) |>
      thmsum(wd = wd) |>
      flextable::htmltools_value()
  })

  # completeness table
  output$tabcom <- renderUI({
    req(fsetls()$res, fsetls()$frecom)

    out <- tabMWRcom(
      res = fsetls()$res,
      frecom = fsetls()$frecom,
      cens = fsetls()$cens,
      warn = F,
      parameterwd = 1.15
    )
    out <- out |>
      flextable::width(
        width = (wd - 3.15) / (flextable::ncol_keys(out) - 2),
        j = 2:(flextable::ncol_keys(out) - 1)
      ) |>
      flextable::htmltools_value()

    return(out)
  })

  # individual field duplicates
  output$indflddup <- renderUI({
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)

    tabMWRacc(
      res = fsetls()$res,
      acc = fsetls()$acc,
      frecom = fsetls()$frecom,
      type = 'individual',
      accchk = 'Field Duplicates',
      warn = F,
      caption = F
    ) |>
      thmsum(wd = wd) |>
      flextable::htmltools_value()
  })

  # individual lab duplicates
  output$indlabdup <- renderUI({
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)

    tabMWRacc(
      res = fsetls()$res,
      acc = fsetls()$acc,
      frecom = fsetls()$frecom,
      type = 'individual',
      accchk = 'Lab Duplicates',
      warn = F,
      caption = F
    ) |>
      thmsum(wd = wd) |>
      flextable::htmltools_value()
  })

  # individual field blanks
  output$indfldblk <- renderUI({
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)

    tabMWRacc(
      res = fsetls()$res,
      acc = fsetls()$acc,
      frecom = fsetls()$frecom,
      type = 'individual',
      accchk = 'Field Blanks',
      warn = F,
      caption = F
    ) |>
      thmsum(wd = wd) |>
      flextable::htmltools_value()
  })

  # individual lab blanks
  output$indlabblk <- renderUI({
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)

    tabMWRacc(
      res = fsetls()$res,
      acc = fsetls()$acc,
      frecom = fsetls()$frecom,
      type = 'individual',
      accchk = 'Lab Blanks',
      warn = F,
      caption = F
    ) |>
      thmsum(wd = wd) |>
      flextable::htmltools_value()
  })

  # individual lab spikes/instrument checks
  output$indlabins <- renderUI({
    req(fsetls()$res, fsetls()$acc, fsetls()$frecom)

    tabMWRacc(
      res = fsetls()$res,
      acc = fsetls()$acc,
      frecom = fsetls()$frecom,
      type = 'individual',
      accchk = 'Lab Spikes / Instrument Checks',
      warn = F,
      caption = F
    ) |>
      thmsum(wd = wd) |>
      flextable::htmltools_value()
  })

  # download qc report word
  output$dwnldqc <- downloadHandler(
    filename = function() {
      'qcreport.docx'
    },
    content = function(file) {
      qcMWRreview(
        fset = fsetls(),
        output_dir = dirname(file),
        output_file = basename(file)
      )
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
    filename = function() {
      'wqxtab.xlsx'
    },
    content = function(file) {
      tabMWRwqx(
        fset = fsetls(),
        output_dir = dirname(file),
        output_file = basename(file)
      )
    }
  )

  # Visualize ----

  output$download_plot_btn <- renderUI({
    req(fsetls()$res, input$param2)
    actionButton(
      "open_plot_download",
      "Download plot",
      icon = icon("download"),
      width = "100%",
      style = "background-color: #64C147; border-color: #64C147; color: white;"
    )
  })

  observeEvent(input$open_plot_download, {
    showModal(modalDialog(
      title = "Download plot",
      size = "s",
      numericInput(
        "plot_width",
        "Width (inches)",
        value = 10,
        min = 1,
        max = 30
      ),
      numericInput(
        "plot_height",
        "Height (inches)",
        value = 6,
        min = 1,
        max = 30
      ),
      numericInput(
        "plot_dpi",
        "Resolution (DPI)",
        value = 150,
        min = 72,
        max = 600
      ),
      selectInput(
        "plot_format",
        "Format",
        choices = c("PNG" = "png", "PDF" = "pdf", "SVG" = "svg")
      ),
      footer = tagList(
        dl_btn("download_plot", "Download"),
        modalButton("Cancel")
      ),
      easyClose = TRUE
    ))
  })

  output$download_plot <- downloadHandler(
    filename = function() {
      paste0(
        input$param2,
        "_",
        tolower(input$viz_selected),
        ".",
        input$plot_format
      )
    },
    content = function(file) {
      fset <- fsetls()
      viz <- input$viz_selected
      param2 <- input$param2
      dtrng2 <- as.character(input$dtrng2)
      sites2 <- input$sites2
      thresh <- if (is.null(input$thresh)) 'none' else input$thresh
      confint2 <- isTRUE(as.logical(input$confint2))

      p <- if (viz == "Season") {
        anlzMWRseason(
          res = fset$res,
          param = param2,
          acc = fset$acc,
          sit = fset$sit,
          thresh = thresh,
          type = input$type2,
          dtrng = dtrng2,
          site = sites2,
          confint = confint2,
          bssize = 18
        ) +
          ggplot2::labs(title = NULL)
      } else if (viz == "Date") {
        anlzMWRdate(
          res = fset$res,
          param = param2,
          acc = fset$acc,
          sit = fset$sit,
          thresh = thresh,
          group = input$group2,
          dtrng = dtrng2,
          site = sites2,
          confint = confint2,
          bssize = 18
        ) +
          ggplot2::labs(title = NULL)
      } else if (viz == "Site") {
        anlzMWRsite(
          res = fset$res,
          param = param2,
          acc = fset$acc,
          sit = fset$sit,
          thresh = thresh,
          type = input$type2,
          dtrng = dtrng2,
          site = sites2,
          confint = confint2,
          bssize = 18
        ) +
          ggplot2::labs(title = NULL)
      } else {
        watsel <- if (isTRUE(input$watsel == "NULL")) NULL else input$watsel
        mapsel <- if (isTRUE(input$mapsel == "NULL")) NULL else input$mapsel
        anlzMWRmap(
          res = fset$res,
          param = param2,
          acc = fset$acc,
          sit = fset$sit,
          dtrng = dtrng2,
          site = sites2,
          addwater = watsel,
          maptype = mapsel,
          bssize = 18
        ) +
          ggplot2::labs(title = NULL)
      }

      ggplot2::ggsave(
        filename = file,
        plot = p,
        width = input$plot_width,
        height = input$plot_height,
        dpi = input$plot_dpi,
        device = input$plot_format
      )
    }
  )

  output$season_plot <- renderPlot({
    # inputs
    thresh <- if (is.null(input$thresh)) 'none' else input$thresh
    param2 <- input$param2
    dtrng2 <- as.character(input$dtrng2)
    sites2 <- input$sites2
    type2 <- input$type2
    confint2 <- isTRUE(as.logical(input$confint2))

    req(fsetls()$res, fsetls()$acc, param2, dtrng2, sites2)
    req(all(sites2 %in% valid_sites2()))

    anlzMWRseason(
      res = fsetls()$res,
      param = param2,
      acc = fsetls()$acc,
      sit = fsetls()$sit,
      thresh = thresh,
      type = type2,
      dtrng = dtrng2,
      site = sites2,
      confint = confint2,
      bssize = 18,
      warn = FALSE
    ) +
      ggplot2::labs(title = NULL)
  })

  output$date_plot <- renderPlot({
    # inputs
    thresh <- if (is.null(input$thresh)) 'none' else input$thresh
    param2 <- input$param2
    dtrng2 <- as.character(input$dtrng2)
    sites2 <- input$sites2
    group2 <- input$group2
    confint2 <- isTRUE(as.logical(input$confint2))

    req(fsetls()$res, fsetls()$acc, param2, dtrng2, sites2)
    req(all(sites2 %in% valid_sites2()))

    anlzMWRdate(
      res = fsetls()$res,
      param = param2,
      acc = fsetls()$acc,
      sit = fsetls()$sit,
      thresh = thresh,
      group = group2,
      dtrng = dtrng2,
      site = sites2,
      confint = confint2,
      bssize = 18,
      warn = FALSE
    ) +
      ggplot2::labs(title = NULL)
  })

  output$site_plot <- renderPlot({
    # inputs
    thresh <- if (is.null(input$thresh)) 'none' else input$thresh
    param2 <- input$param2
    dtrng2 <- as.character(input$dtrng2)
    sites2 <- input$sites2
    type2 <- input$type2
    confint2 <- isTRUE(as.logical(input$confint2))

    req(fsetls()$res, fsetls()$acc, param2, dtrng2, sites2)
    req(all(sites2 %in% valid_sites2()))

    anlzMWRsite(
      res = fsetls()$res,
      param = param2,
      acc = fsetls()$acc,
      sit = fsetls()$sit,
      thresh = thresh,
      type = type2,
      dtrng = dtrng2,
      site = sites2,
      confint = confint2,
      bssize = 18,
      warn = FALSE
    ) +
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

    if (watsel == 'NULL') {
      watsel <- NULL
    }
    if (mapsel == 'NULL') {
      mapsel <- NULL
    }

    anlzMWRmap(
      res = fsetls()$res,
      param = param2,
      acc = fsetls()$acc,
      sit = fsetls()$sit,
      dtrng = dtrng2,
      site = sites2,
      addwater = watsel,
      maptype = mapsel,
      bssize = 18,
      warn = FALSE
    ) +
      ggplot2::labs(title = NULL)
  })
}

shinyApp(ui = ui, server = server)
