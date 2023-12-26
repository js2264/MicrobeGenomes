#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
    tagList(

        golem_add_external_resources(),

        # fluidPage(
        #     titlePanel("Microbe Genomes Community"),
        #     splitLayout(
        #         cellWidths = c("33%", "66%"),
        #         sliderInput(
        #             "bins", label = "Number of bins:",
        #             min = 1, value = 30, max = 50
        #         ) |> wellPanel(),
        #         splitLayout(
        #             cellWidths = c("50%", "50%"),
        #             plotOutput("plot"), 
        #             textOutput("text")
        #         ) |> wellPanel()
        #     )
        # )

        shinydashboardPlus::dashboardPage(
            header = shinydashboardPlus::dashboardHeader(
                title = "Microbe Genomes Community", 
                titleWidth = '20%'
            ),
            sidebar = shinydashboardPlus::dashboardSidebar(
                width = "20%", 
                selectizeInput(
                    "species", 
                    "Pick a microbe: ", 
                    choices = shinipsum::lorem_words[1:1000], 
                    selected = 1, 
                    multiple = FALSE
                ) 
            ),
            body = shinydashboard::dashboardBody(
                column(12,
                    fluidRow(
                        column(4,
                            h2("Genome reference metrics"), 
                            dataTableOutput("metrics"),
                        ), 
                        column(4,
                            h2("Contact matrix"), 
                            plotOutput("map"),
                        ),
                        column(4,
                            h2("Genome structural features"), 
                            dataTableOutput("structural_features"),
                        )
                    ), 
                    br(),
                    br(),
                    fluidRow(
                        column(4,
                            h2("Data access"),
                            textOutput("data"),
                        ), 
                        column(4,
                            h2("P(s) representation"), 
                            plotOutput("ps"),
                        ),
                        column(4,
                            h2("Aggregated plot"), 
                            plotOutput("aggregated"),
                        )
                    )
                )
            )
        )
    )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
    add_resource_path(
        "www",
        app_sys("app/www")
    )

    tags$head(
        favicon(),
        bundle_resources(
            path = app_sys("app/www"),
            app_title = "MicrobeGenomes"
        )
        # Add here other external resources
        # for example, you can add shinyalert::useShinyalert()
    )
}
