db <- DBI::dbConnect(
    RSQLite::SQLite(), 
    system.file('extdata', 'MicrobeGenomes.sqlite', package = 'MicrobeGenomes')
)
available_species <- dplyr::tbl(db, "REFERENCES") |> 
    dplyr::collect() |> 
    dplyr::pull(sample) |> 
    unique() |> 
    sort()
