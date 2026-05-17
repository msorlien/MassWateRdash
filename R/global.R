library(shiny)
library(bslib)
library(bsicons)
library(MassWateR)
library(rhandsontable)
library(here)
library(shinyWidgets)

source(here('R/funcs.R'))
source(here('R/mod_wqformat.R'))
source(here('R/utils_wqformat.R'))

tabfontsize <- 10 
padding <- 0
dqofontsize <- 10
wd <- 6.5

flextable::set_flextable_defaults(font.size = tabfontsize, padding = padding)