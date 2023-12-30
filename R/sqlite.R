populate_db <- function() {

    processed_files <- system.file('extdata', 'processed_files.csv', package = 'MicrobeGenomes')
    db_path <- system.file('extdata', 'MicrobeGenomes.sqlite', package = 'MicrobeGenomes')
    db <- .populate(db_path, processed_files)

}

.populate <- function(db_path, processed_files_path) {

    # FILES sqlite table:
    # |_ Kingdom          <chr>
    # |_ Phylum           <chr>
    # |_ Class            <chr>
    # |_ Order            <chr>
    # |_ Family           <chr>
    # |_ Genus            <chr>
    # |_ Species          <chr>
    # |_ Strain           <chr>
    # |_ file             <chr>
    # |_ type             <chr>

    ## Purge old db 
    if (file.exists(db_path)) unlink(db_path)
    
    ## Create a fresh db with a FILES table listing all processed files
    db <- DBI::dbConnect(RSQLite::SQLite(), db_path)
    processed_files <- read.csv(processed_files_path) |> tibble::as_tibble()
    files <- processed_files |> 
        dplyr::select(c(Kingdom, Phylum, Class, Order, Family, Genus, Species, Strain, file, type)) |> 
        dplyr::group_by(Genus, Species, Strain) |> 
        dplyr::arrange(Genus, Species, Strain) |> 
        dplyr::rowwise() |>
        dplyr::mutate(
            hash = paste(sample(c(letters, 0:9), 12), collapse = "")
        )
    RSQLite::dbWriteTable(db, "FILES", files, overwrite = TRUE)
    RSQLite::dbDisconnect(db)
    return(db)

}

.populate_refs <- function(db) {

    # REFERENCES sqlite table:
    # |_ Genus        <chr>
    # |_ Species      <chr>
    # |_ Strain      <chr>
    # |_ fasta        <chr>

    dir <- file.path(.DBZ_DATA_DIR, 'ToB')
    fasta_f <- dir |> list.files(pattern = '*.fa$', full.names = TRUE)
    df <- tibble::tibble(fasta = fasta_f) |> 
        dplyr::mutate(sample = stringr::str_replace(fasta, dir, '') |> 
            stringr::str_replace(".fa$", '') |> 
            stringr::str_replace("^/", '')
        ) |> 
        dplyr::mutate(sample2 = sample) |> 
        tidyr::separate_wider_delim(cols = sample2, names = c('Genus', 'Species', 'Strain'), delim = '_', too_few = "align_start", too_many = 'merge') |> 
        dplyr::relocate(fasta, .after = Strain)

    db <- RSQLite::dbConnect(db)
    RSQLite::dbWriteTable(db, "REFERENCES", df, overwrite = TRUE)
    RSQLite::dbDisconnect(db)
    return(db)

}

.populate_maps <- function(db) {

    # MAPS sqlite table:
    # |_ sample      <chr>
    # |_ library     <chr>
    # |_ mcool       <chr>

    db <- RSQLite::dbConnect(db)
    refs <- dplyr::tbl(db, "REFERENCES") |> dplyr::collect()

    dir <- file.path(.DBZ_DATA_DIR, 'cool')
    cool_f <- dir |> list.files(pattern = '*.mcool$', full.names = TRUE)
    df <- tibble::tibble(mcool = cool_f) |> 
        dplyr::mutate(sample = stringr::str_replace(mcool, dir, '') |> 
            stringr::str_replace(".mcool$", '') |> 
            stringr::str_replace("^/", '')
        ) |> 
        dplyr::mutate(library = stringr::str_replace(sample, ".*_", '')) |>
        tidyr::separate_wider_delim(cols = sample, names = c('Genus', 'Species', 'Strain'), delim = '_', too_few = "align_start", too_many = 'drop') |> 
        dplyr::mutate(Strain = ifelse(Strain == library, NA, Strain)) |> 
        dplyr::relocate(mcool, .after = library) |> 
        dplyr::left_join(
            dplyr::select(refs, sample, Species), 
            y = _, 
            by = "Species", 
            relationship = "many-to-many"
        ) |> 
            dplyr::select(-Species, -Genus, -Strain) |> 
            tidyr::drop_na(mcool)

    RSQLite::dbWriteTable(db, "MAPS", df, overwrite = TRUE)
    RSQLite::dbDisconnect(db)
    return(db)

}

.populate_ps <- function(db) {

    # DISTANCELAW sqlite table:
    # |_ sample      <chr>
    # |_ library     <chr>
    # |_ ps          <chr>

    db <- DBI::dbConnect(db)
    refs <- dplyr::tbl(db, "REFERENCES") |> dplyr::collect()

    dir <- file.path(.DBZ_DATA_DIR, 'distance_law')
    ps_f <- dir |> list.files(pattern = '*.csv$', full.names = TRUE)
    df <- tibble::tibble(ps = ps_f) |> 
        dplyr::mutate(sample = stringr::str_replace(ps, dir, '') |> 
            stringr::str_replace("_distance_law.csv$", '') |> 
            stringr::str_replace("^/", '')
        ) |> 
        dplyr::mutate(library = stringr::str_replace(sample, ".*_", '')) |>
        tidyr::separate_wider_delim(cols = sample, names = c('Genus', 'Species', 'Strain'), delim = '_', too_few = "align_start", too_many = 'drop') |> 
        dplyr::mutate(Strain = ifelse(Strain == library, NA, Strain)) |> 
        dplyr::relocate(ps, .after = library) |> 
        dplyr::left_join(
            dplyr::select(refs, sample, Species), 
            y = _, 
            by = "Species", 
            relationship = "many-to-many"
        ) |> 
            dplyr::select(-Species, -Genus, -Strain) |> 
            tidyr::drop_na(ps)

    RSQLite::dbWriteTable(db, "DISTANCELAW", df, overwrite = TRUE)
    RSQLite::dbDisconnect(db)
    return(db)

}

.populate_pairs <- function(db) {

    # FEATURES sqlite table:
    # |_ sample      <chr>
    # |_ library     <chr>
    # |_ pairs       <chr>
    # |_ file        <chr>

    db <- RSQLite::dbConnect(db)
    refs <- dplyr::tbl(db, "REFERENCES") |> dplyr::collect()

    dir <- file.path(.DBZ_DATA_DIR, 'pairs')
    pairs_f <- dir |> list.files(pattern = '*.pairs$', full.names = TRUE)
    df <- tibble::tibble(pairs = "pairs", file = pairs_f) |> 
        dplyr::mutate(sample = stringr::str_replace(file, dir, '') |> 
            stringr::str_replace(".pairs$", '') |> 
            stringr::str_replace("^/", '')
        ) |> 
        dplyr::mutate(pairs = grepl('_filtered', sample)) |>
        dplyr::mutate(pairs = ifelse(pairs, 'filtered', 'unfiltered')) |>
        dplyr::mutate(sample = stringr::str_replace(sample, '_filtered', '')) |>
        dplyr::mutate(library = stringr::str_replace(sample, ".*_", '')) |>
        tidyr::separate_wider_delim(cols = sample, names = c('Genus', 'Species', 'Strain'), delim = '_', too_few = "align_start", too_many = 'drop') |> 
        dplyr::mutate(Strain = ifelse(Strain == library, NA, Strain)) |> 
        dplyr::relocate(pairs, .after = library) |> 
        dplyr::relocate(file, .after = pairs) |> 
        dplyr::left_join(
            dplyr::select(refs, sample, Species), 
            y = _, 
            by = "Species", 
            relationship = "many-to-many"
        ) |> 
            dplyr::select(-Species, -Genus, -Strain) |> 
            tidyr::drop_na(file)

    RSQLite::dbWriteTable(db, "PAIRS", df, overwrite = TRUE)
    RSQLite::dbDisconnect(db)
    return(db)

}

.populate_features <- function(db) {

    # FEATURES sqlite table:
    # |_ sample      <chr>
    # |_ library     <chr>
    # |_ feature     <chr>
    # |_ file        <chr>

    # Available features: macrodomains, DI, insulations, borders, chromosight loops
    db <- RSQLite::dbConnect(db)
    refs <- dplyr::tbl(db, "REFERENCES") |> dplyr::collect()

    dir <- file.path(.DBZ_DATA_DIR, 'macrodomains')
    macro_f <- dir |> list.files(pattern = '*.bed$', full.names = TRUE)
    df_macro <- tibble::tibble(feature = "macrodomains", file = macro_f) |> 
        dplyr::mutate(sample = stringr::str_replace(file, dir, '') |> 
            stringr::str_replace("_macrodomains.bed$", '') |> 
            stringr::str_replace("^/", '')
        ) |> 
        dplyr::mutate(library = stringr::str_replace(sample, ".*_", '')) |>
        tidyr::separate_wider_delim(cols = sample, names = c('Genus', 'Species', 'Strain'), delim = '_', too_few = "align_start", too_many = 'drop') |> 
        dplyr::mutate(Strain = ifelse(Strain == library, NA, Strain)) |> 
        dplyr::relocate(feature, .after = library) |> 
        dplyr::relocate(file, .after = feature) |> 
        dplyr::left_join(
            dplyr::select(refs, sample, Species), 
            y = _, 
            by = "Species", 
            relationship = "many-to-many"
        ) |> 
            dplyr::select(-Species, -Genus, -Strain) |> 
            tidyr::drop_na(file)

    dir <- file.path(.DBZ_DATA_DIR, 'DI')
    DI_f <- dir |> list.files(pattern = '*.bed$', full.names = TRUE)
    df_DI <- tibble::tibble(feature = "DI", file = DI_f) |> 
        dplyr::mutate(sample = stringr::str_replace(file, dir, '') |> 
            stringr::str_replace("_DI.bed$", '') |> 
            stringr::str_replace("^/", '')
        ) |> 
        dplyr::mutate(library = stringr::str_replace(sample, ".*_", '')) |>
        tidyr::separate_wider_delim(cols = sample, names = c('Genus', 'Species', 'Strain'), delim = '_', too_few = "align_start", too_many = 'drop') |> 
        dplyr::mutate(Strain = ifelse(Strain == library, NA, Strain)) |> 
        dplyr::relocate(feature, .after = library) |> 
        dplyr::relocate(file, .after = feature) |> 
        dplyr::left_join(
            dplyr::select(refs, sample, Species), 
            y = _, 
            by = "Species", 
            relationship = "many-to-many"
        ) |> 
            dplyr::select(-Species, -Genus, -Strain) |> 
            tidyr::drop_na(feature)

    dir <- file.path(.DBZ_DATA_DIR, 'insulation')
    insulation_f <- dir |> list.files(pattern = '*.bed$', full.names = TRUE)
    df_insul <- tibble::tibble(feature = "insulation", file = insulation_f) |> 
        dplyr::mutate(sample = stringr::str_replace(file, dir, '') |> 
            stringr::str_replace("_insulation.bed$", '') |> 
            stringr::str_replace("^/", '')
        ) |> 
        dplyr::mutate(library = stringr::str_replace(sample, ".*_", '')) |>
        tidyr::separate_wider_delim(cols = sample, names = c('Genus', 'Species', 'Strain'), delim = '_', too_few = "align_start", too_many = 'drop') |> 
        dplyr::mutate(Strain = ifelse(Strain == library, NA, Strain)) |> 
        dplyr::relocate(feature, .after = library) |> 
        dplyr::relocate(file, .after = feature) |> 
        dplyr::left_join(
            dplyr::select(refs, sample, Species), 
            y = _, 
            by = "Species", 
            relationship = "many-to-many"
        ) |> 
            dplyr::select(-Species, -Genus, -Strain) |> 
            tidyr::drop_na(feature)

    dir <- file.path(.DBZ_DATA_DIR, 'borders')
    borders_f <- dir |> list.files(pattern = '*.bed$', full.names = TRUE)
    df_borders <- tibble::tibble(feature = "borders", file = borders_f) |> 
        dplyr::mutate(sample = stringr::str_replace(file, dir, '') |> 
            stringr::str_replace("_borders.bed$", '') |> 
            stringr::str_replace("^/", '')
        ) |> 
        dplyr::mutate(library = stringr::str_replace(sample, ".*_", '')) |>
        tidyr::separate_wider_delim(cols = sample, names = c('Genus', 'Species', 'Strain'), delim = '_', too_few = "align_start", too_many = 'drop') |> 
        dplyr::mutate(Strain = ifelse(Strain == library, NA, Strain)) |> 
        dplyr::relocate(feature, .after = library) |> 
        dplyr::relocate(file, .after = feature) |> 
        dplyr::left_join(
            dplyr::select(refs, sample, Species), 
            y = _, 
            by = "Species", 
            relationship = "many-to-many"
        ) |> 
            dplyr::select(-Species, -Genus, -Strain) |> 
            tidyr::drop_na(feature)

    dir <- file.path(.DBZ_DATA_DIR, 'chromosight')
    loops_f <- dir |> list.files(pattern = '*.tsv$', full.names = TRUE)
    df_loops <- tibble::tibble(feature = "loops", file = loops_f) |> 
        dplyr::mutate(sample = stringr::str_replace(file, dir, '') |> 
            stringr::str_replace("_loops.tsv$", '') |> 
            stringr::str_replace("^/", '')
        ) |> 
        dplyr::mutate(library = stringr::str_replace(sample, ".*_", '')) |>
        tidyr::separate_wider_delim(cols = sample, names = c('Genus', 'Species', 'Strain'), delim = '_', too_few = "align_start", too_many = 'drop') |> 
        dplyr::mutate(Strain = ifelse(Strain == library, NA, Strain)) |> 
        dplyr::relocate(feature, .after = library) |> 
        dplyr::relocate(file, .after = feature) |> 
        dplyr::left_join(
            dplyr::select(refs, sample, Species), 
            y = _, 
            by = "Species", 
            relationship = "many-to-many"
        ) |> 
            dplyr::select(-Species, -Genus, -Strain) |> 
            tidyr::drop_na(feature)

    df <- rbind(df_macro, df_DI, df_insul, df_borders, df_loops)
    RSQLite::dbWriteTable(db, "FEATURES", df, overwrite = TRUE)
    RSQLite::dbDisconnect(db)
    return(db)

}
