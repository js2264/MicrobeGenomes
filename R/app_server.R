#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
    
    species <- reactive ({ input$species })

    output$metrics <- DT::renderDT({
        shinipsum::random_DT(5, 5)
    })
    output$data <- renderText({
        shinipsum::random_text(nwords = 50)
    })

    output$map <- renderPlot({
        shinipsum::random_ggplot()
    })
    output$ps <- renderPlot({
        shinipsum::random_ggplot()
    })

    output$structural_features <- DT::renderDT({
        shinipsum::random_DT(5, 5)
    })
    output$aggregated <- renderPlot({
        shinipsum::random_ggplot()
    })
}
