makeButtons <- function(hashes) {
    inputs <- character(length = length(hashes))
    names(inputs) <- hashes
    for (hash in hashes) inputs[hash] <- as.character(  
        actionButton(
            inputId = paste0("aButton_", hash),  
            label   = icon("floppy-disk"), 
            onclick = 'Shiny.onInputChange(\"selected_button\", this.id, {priority: \"event\"})'
        )
    )
    inputs
}
