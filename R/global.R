library(cicerone)
set.seed(42)
local <- TRUE 

################################################################################
############### [ SETTINGS TO CHANGE IF RUNNING LOCAL OR EC2+S3] ###############
################################################################################

processed_files <- '/mnt/data/processed_files.csv'
s3_mounting <- '/mnt/data/'

if (local) {
    s3_mounting <- '/home/rsg/repos/MicrobeGenomes/data/'
    processed_files <- system.file('extdata', 'processed_files.csv', package = 'MicrobeGenomes')
}

################################################################################
################################################################################
################################################################################

files <- processed_files |> 
    read.csv() |> 
    tibble::as_tibble() |> 
    dplyr::mutate(sample = paste0(Genus, "_", Species, "_", Strain)) |> 
    dplyr::rowwise() |>
    dplyr::mutate(hash = paste(sample(c(letters, 0:9), 12), collapse = "")) |> 
    dplyr::mutate(file = file.path(s3_mounting, file)) |> 
    dplyr::mutate(file = stringr::str_replace(file, '/results/', '')) |> 
    dplyr::group_by(sample)

available_species <- files |> 
    dplyr::pull(sample) |> 
    unique() |> 
    sort()

available_features <- c("macrodomains", "DI", "insulation", "borders", "chromosight")
