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
        metrics <- .get_metrics(input$select_species, db = db)
        reactive_values$metrics <- metrics[[1]]
        reactive_values$contigs <- metrics[[2]]
        reactive_values$data <- .get_data(input$select_species, db = db)
        reactive_values$map <- .get_map(input$select_species, db = db)
        reactive_values$ps <- .get_ps(input$select_species, db = db)
        reactive_values$structural_features <- .get_features(input$select_species, db = db)
        reactive_values$aggregated <- .get_aggr_plot(input$select_species, db = db)
    })

    ## Render download buttons
    observeEvent(input$trigger, {
        req(input$trigger)
        
        ## Data
        data <- .get_data(input$select_species, db = db)
        if (!is.null(data)) {
            for (K in seq_len(nrow(data))) {
                hash <- data$hash[K]
                output[[glue::glue("dl_data_{hash}")]] <- shiny::downloadHandler(
                    filename = function() {basename(data$File[K])}, 
                    content = function(file) {
                        tmpf <- tempfile()
                        system(glue::glue("cp {data$File[K]} {tmpf}"))
                        file.copy(tmpf, file)
                    }
                )
            }
        }

        ## Features
        features <- .get_features(input$select_species, db = db)
        print(features)
        if (!is.null(features)) {
            for (K in seq_len(nrow(features))) {
                hash <- features$hash[K]
                output[[glue::glue("dl_features_{hash}")]] <- shiny::downloadHandler(
                    filename = function() {basename(features$File[K])}, 
                    content = function(file) {
                        tmpf <- tempfile()
                        system(glue::glue("cp {features$File[K]} {tmpf}"))
                        file.copy(tmpf, file)
                    }
                )
            }
        }
    })

    ## Render facets and send to UI
    output$metrics <- reactive({
        reactive_values$metrics |> 
            kableExtra::kable(col.names = NULL) |> 
            kableExtra::kable_styling(bootstrap_options = c("striped", "hover", "condensed")) 
    })
    output$contigs <- reactive({
        reactive_values$contigs |> 
            kableExtra::kable() |> 
            kableExtra::kable_styling(bootstrap_options = c("striped", "hover", "condensed"))
    })
    output$data <- DT::renderDataTable({
        DT::datatable(
            reactive_values$data,
            selection = list(mode = "none"),
            rownames = FALSE,
            extensions = c("Scroller"),
            escape = FALSE,
            options = list(
                preDrawCallback = DT::JS("function() { Shiny.unbindAll(this.api().table().node()); }"),
                drawCallback = DT::JS("function() { Shiny.bindAll(this.api().table().node()); } "),
                scroller = TRUE,
                scrollX = 200,
                scrollY = 400,
                searching = FALSE, 
                ordering = FALSE
            )
        )
    })
    output$map <- renderPlot({
        reactive_values$map
    })
    output$ps <- renderPlot({
        reactive_values$ps
    })
    output$structural_features <- DT::renderDataTable({
        DT::datatable(
            reactive_values$structural_features,
            selection = list(mode = "none"),
            rownames = FALSE,
            extensions = c("Scroller"),
            escape = FALSE,
            options = list(
                preDrawCallback = DT::JS("function() { Shiny.unbindAll(this.api().table().node()); }"),
                drawCallback = DT::JS("function() { Shiny.bindAll(this.api().table().node()); } "),
                scroller = TRUE,
                scrollX = 200,
                scrollY = 400,
                searching = FALSE, 
                ordering = FALSE
            )
        )
    })
    output$aggregated <- renderPlot({
        reactive_values$aggregated
    })
}
