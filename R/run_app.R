#' @export 
run_app <- function(
    onStart = NULL,
    options = list(),
    enableBookmarking = NULL,
    uiPattern = "/"
) {
    shinyApp(
        ui = app_ui,
        server = app_server,
        onStart = onStart,
        options = options,
        enableBookmarking = enableBookmarking,
        uiPattern = uiPattern
    )
}
