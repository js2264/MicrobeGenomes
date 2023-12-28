#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
    
    ## Start-up ops
    populate_db(.DBZ_DATA_DIR = '/data/DBZ')
    db <- DBI::dbConnect(
        RSQLite::SQLite(), 
        system.file('extdata', 'MicrobeGenomes.sqlite', package = 'MicrobeGenomes')
    )
    available_species <- dplyr::tbl(db, "REFERENCES") |> 
        dplyr::collect() |> 
        dplyr::pull(sample) |> 
        unique() |> 
        sort()
    reactive_values <- reactiveValues(
        metrics = NULL,
        data = NULL,
        map = NULL,
        ps = NULL,
        structural_features = NULL,
        aggregated = NULL
    )

    ## Generate facets upon input trigger
    observeEvent(input$trigger, {
        reactive_values$metrics <- .get_metrics(input$select_species, db = db)
        reactive_values$data <- .get_data(input$select_species, db = db)
        reactive_values$map <- .get_map(input$select_species, db = db)
        reactive_values$ps <- .get_ps(input$select_species, db = db)
        reactive_values$structural_features <- .get_features(input$select_species, db = db)
        reactive_values$aggregated <- .get_aggr_plot(input$select_species, db = db)
    })

    ## Render facets and send to UI
    output$metrics <- DT::renderDT({
        reactive_values$metrics
    })
    output$data <- renderText({
        reactive_values$data
    })
    output$map <- renderPlot({
        reactive_values$map
    })
    output$ps <- renderPlot({
        reactive_values$ps
    })
    output$structural_features <- DT::renderDT({
        reactive_values$structural_features
    })
    output$aggregated <- renderPlot({
        reactive_values$aggregated
    })
}
