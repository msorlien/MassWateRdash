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
