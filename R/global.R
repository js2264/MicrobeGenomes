library(cicerone)
set.seed(42)

files_dir <- '/home/rsg/repos/MicrobeGenomes/DBZ/'

files <- system.file('extdata', 'processed_files.csv', package = 'MicrobeGenomes') |> 
    read.csv() |> 
    tibble::as_tibble() |> 
    dplyr::mutate(sample = paste0(Genus, "_", Species, "_", Strain)) |> 
    dplyr::rowwise() |>
    dplyr::mutate(hash = paste(sample(c(letters, 0:9), 12), collapse = "")) |> 
    dplyr::mutate(file = file.path(files_dir, file)) |> 
    dplyr::group_by(sample)

available_species <- files |> 
    dplyr::pull(sample) |> 
    unique() |> 
    sort()

available_features <- c("macrodomains", "DI", "insulation", "borders", "chromosight")
