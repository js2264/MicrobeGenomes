app_server <- function(input, output, session) {
    
    ## Start-up ops
    reactive_values <- reactiveValues(
        metrics = NULL,
        data = NULL,
        map = NULL,
        ps = NULL,
        features = NULL,
        aggregated = NULL
    )

    ## Support for cicerone/glouton
    observeEvent(input$loaded, {
        visited <- glouton::fetch_cookies()
        print(visited$visited_site)
        
        # if null, set cookie and show guide
        if (is.null(visited$visited_site)) {
            glouton::add_cookie("visited_site", "yes")
            guide <- cicerone::Cicerone$
                new()$ 
                step(
                    el = "select_species",
                    title = "Test",
                    description = "Start by picking your favorite bacteria."
                )$ 
                step(
                    el = "trigger",
                    title = "Test",
                    description = "Then click on the Search button."
                )
            guide$init()$start()
        }
    })

    ## Render all download buttons and generate links
    fClicks <- reactiveValues()
    for ( hash in files$hash ) {
        fClicks[[paste0("firstClick_", hash)]] <- FALSE
    }
    output$hidden_downloads <- renderUI(
        lapply(
            files$hash, 
            function(hash) downloadLink(paste0("dButton_", hash), label="")
        )
    )

    ## Generate facets upon input trigger
    observeEvent(input$trigger, ignoreInit = FALSE, ignoreNULL = FALSE, {
        metrics <- .get_metrics(input$select_species, files = files)
        reactive_values$metrics <- metrics[[1]]
        reactive_values$contigs <- metrics[[2]]
        reactive_values$data <- .get_data(input$select_species, files = files)
        reactive_values$map <- .get_map(input$select_species, files = files)
        reactive_values$ps <- .get_ps(input$select_species, files = files)
        reactive_values$features <- .get_features(input$select_species, files = files)
        reactive_values$aggregated <- .get_aggr_plot(input$select_species, files = files)
    })

    ## Generate download handlers
    observeEvent(input$trigger, ignoreInit = FALSE, ignoreNULL = FALSE, {
        data <- reactive_values$data
        features <- reactive_values$features
        lapply(
            c(data$hash, features$hash), 
            function(hash) {
                output[[paste0("dButton_", hash)]] <- downloadHandler(
                    filename = function() basename(files$file[files$hash==hash]),
                    content  = function(file) {
                        withProgress(message = "Fetching file...", value = 0, {
                            incProgress(0.1, detail = "Copying file to tmp directory")
                            tmpf <- file.path(tempdir(), basename(files$file[files$hash==hash]))
                            system(glue::glue("cp {files$file[files$hash==hash]} {tmpf}"))
                            incProgress(0.7, detail = "Downloading file")
                            file.copy(tmpf, file)
                        })
                    }
                )
            }
        )
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
            reactive_values$data |> 
                dplyr::mutate(File = basename(File)) |> 
                dplyr::select(-hash),
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
                scrollCollapse = TRUE, 
                searching = FALSE, 
                server = FALSE,
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
    output$features <- DT::renderDataTable({
        DT::datatable(
            reactive_values$features |> 
                dplyr::mutate(File = basename(File)) |> 
                dplyr::select(-hash),
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
                scrollCollapse = TRUE, 
                searching = FALSE, 
                server = FALSE,
                ordering = FALSE
            )
        )
    })
    output$aggregated <- renderPlot({
        reactive_values$aggregated
    })

    ## Trigger specific downloads
    observeEvent(input$selected_button, {
    
        data <- reactive_values$data
        features <- reactive_values$features
        i <- strsplit(input$selected_button, "_")[[1]][2]
        print(i)
        shinyjs::runjs(paste0("document.getElementById('aButton_",i,"').addEventListener('click',function(){",
                                "setTimeout(function(){document.getElementById('dButton_",i,"').click();},0)});"))

        # Duplicating the first click
        if(!fClicks[[paste0("firstClick_", i)]]) {
            shinyjs::click(paste0('aButton_', i))
            fClicks[[paste0("firstClick_",i)]] <- TRUE
        }
    })

}
