#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
    tagList(

        golem_add_external_resources(),

        bs4Dash::dashboardPage(
            title = "Microbe Genomes Community", 
            freshTheme = app_theme(), 
            header = bs4Dash::dashboardHeader(
                disable = TRUE, 
                titleWidth = '20%'
            ),
            sidebar = bs4Dash::dashboardSidebar(
                width = "20%", 
                skin = 'light', 
                selectizeInput(
                    "species", 
                    "Pick a microbe: ", 
                    choices = shinipsum::lorem_words[1:1000], 
                    selected = 1, 
                    multiple = FALSE
                ) 
            ),
            body = bs4Dash::dashboardBody(shiny::fluidPage(
                shiny::fluidRow(
                    bs4Dash::column(4, bs4Dash::box(
                        title = "Genome reference metrics",
                        status = "white",
                        solidHeader = TRUE,
                        DT::dataTableOutput("metrics"),
                        width = 12,
                        collapsible = FALSE
                    )), 
                    bs4Dash::column(4, bs4Dash::box(
                        title = "Contact matrix",
                        status = "white",
                        solidHeader = TRUE,
                        plotOutput("map"),
                        width = 12,
                        collapsible = FALSE
                    )), 
                    bs4Dash::column(4, bs4Dash::box(
                        title = "Genome structural features",
                        status = "white",
                        solidHeader = TRUE,
                        DT::dataTableOutput("structural_features"),
                        width = 12,
                        collapsible = FALSE
                    ))
                ), 
                br(),
                br(),
                shiny::fluidRow(
                    bs4Dash::column(4, bs4Dash::box(
                        title = "Data access",
                        status = "white",
                        solidHeader = TRUE,
                        textOutput("data"),
                        width = 12,
                        collapsible = FALSE
                    )), 
                    bs4Dash::column(4, bs4Dash::box(
                        title = "P(s) representation",
                        status = "white",
                        solidHeader = TRUE,
                        plotOutput("ps"),
                        width = 12,
                        collapsible = FALSE
                    )), 
                    bs4Dash::column(4, bs4Dash::box(
                        title = "Aggregated plot",
                        status = "white",
                        solidHeader = TRUE,
                        plotOutput("aggregated"),
                        width = 12,
                        collapsible = FALSE
                    ))
                )
            )), 
            fullscreen = TRUE, 
            help = TRUE,
            dark = NULL, 
            preloader = list(html = waiter::spin_folding_cube(), color = "#3e5368")
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

app_theme <- function() {
    fresh::create_theme(
        fresh::bs4dash_vars(
            navbar_light_color = "#7c7b7b",
            navbar_light_active_color = "#272c30",
            navbar_light_hover_color = "#272c30"
        ),
        fresh::bs4dash_yiq(
            contrasted_threshold = 10,
            text_dark = "#272c30",
            text_light = "#FFFFFF"
        ),
        fresh::bs4dash_layout(
            main_bg = "#f5f5f5"
        ),
        fresh::bs4dash_sidebar_light(
            bg = "#FFFFFF",
            color = "#bec5cb",
            hover_color = "#FFF",
            submenu_bg = "#FFFFFF",
            submenu_color = "#272c30",
            submenu_hover_color = "#272c30"
        ),
        fresh::bs4dash_status(
            primary = "#8eaacc", secondary = "#5E81AC", success = "#7cbd7e",
            warning = "#e9d479", info = "#5c6692", danger = "#BF616A",
            light = "#FFFFFF", dark = NULL
        ),
        fresh::bs4dash_color(
            gray_900 = "#272c30", white = "#FFFFFF"
        )
    )
}
