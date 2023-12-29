#' @import shiny
#' @include globals.R
app_ui <- function(request) {
    tagList(
        add_external_resources(),
        bs4Dash::dashboardPage(
            title = "Microbe Genomes Community", 
            help = NULL, 
            dark = NULL, 
            freshTheme = app_theme(), 
            preloader = list(html = waiter::spin_folding_cube(), color = "#3e5368"), 
            header = header,
            sidebar = sidebar,
            body = body, 
            footer = footer
        )
    )
}

header <- bs4Dash::dashboardHeader(
    status = 'light', titleWidth = '0%', 
    border = FALSE
)

footer <- bs4Dash::dashboardFooter(
    left = 'Copyright rsg | 2023 - present', 
    right = 'Developed by J. Serizay with Shiny in R'
)

sidebar <- bs4Dash::dashboardSidebar(#disable = TRUE)
    skin = 'light', 
    status = 'light', 
    elevation = 2, 
    minified = TRUE, 
    collapsed = TRUE, 
    bs4Dash::sidebarMenu(
        id = "sidebarmenu",
        flat = FALSE, 
        compact = FALSE, 
        legacy = TRUE, 
        div(
            selectizeInput(
                inputId = "select_species", 
                label = NULL, 
                choices = available_species, 
                width = '100%', 
                options = list(
                    placeholder = 'Pick your favorite microbe',
                    onInitialize = I('function() { this.setValue(""); }')
                )
            ), 
            bs4Dash::actionButton(
                inputId = "trigger",
                status = "info",
                label = bs4Dash::ionicon('search')
            )
        )
    )
)

body <- bs4Dash::dashboardBody(
    shiny::fluidPage(shiny::fluidRow(
        bs4Dash::column(width = 4, 
            bs4Dash::box(
                width = 12, 
                title = "Genome assembly metrics",
                shiny::tableOutput("metrics")
            ), 
            bs4Dash::box(
                id = "card_data",
                width = 12, 
                title = "Data access",
                DT::dataTableOutput("data")
            ), 
            bs4Dash::box(
                width = 12, 
                title = "Contigs",
                shiny::tableOutput("contigs")
            )
        ), 
        bs4Dash::column(width = 4,  
            bs4Dash::box(
                width = 12, 
                title = "Contact matrix",
                shiny::plotOutput("map")
            ), 
            bs4Dash::box(
                width = 12, 
                title = "P(s) representation",
                plotOutput("ps")
            )
        ), 
        bs4Dash::column(width = 4, 
            bs4Dash::box(
                width = 12, 
                title = "Genome structural features",
                DT::dataTableOutput("structural_features")
            ), 
            bs4Dash::box(
                width = 12, 
                title = "Aggregated plot",
                plotOutput("aggregated")
            )
        )
    ))
)

add_external_resources <- function() {
    golem::add_resource_path(
        "www",
        system.file('app', 'www', package = "MicrobeGenomes")
    )
    tags$head(
        golem::favicon(), 
        golem::bundle_resources(
            path = system.file('app', 'www', package = "MicrobeGenomes"),
            app_title = "MicrobeGenomes"
        ), 
        waiter::autoWaiter(
            html = waiter::spin_folding_cube(), 
            color = "#d4d4d4"
        )
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
            sidebar_width = "25%",
            main_bg = "#f5f5f5"
        ),
        fresh::bs4dash_sidebar_light(
            bg = "#f5f5f5",
            color = "#6d6d6d",
            hover_color = "#FFF",
            submenu_bg = "#f5f5f5",
            submenu_color = "#272c30",
            submenu_hover_color = "#272c30"
        ),
        fresh::bs4dash_status(
            primary = "#8eaacc", secondary = "#5E81AC", success = "#7cbd7e",
            warning = "#e9d479", info = "#acacac", danger = "#BF616A",
            light = "#f5f5f5", dark = "#acacac"
        ),
        fresh::bs4dash_color(
            gray_900 = "#272c30", white = "#FFFFFF"
        )
    )
}
