populate_db <- function(.DBZ_DATA_DIR = '/data/DBZ') {

    db_path <- system.file('extdata', 'MicrobeGenomes.sqlite', package = 'MicrobeGenomes')

    ## Initiate an emtpy sqlite
    db <- .init_sqlite(db_path) |> 

        ## Find sample IDs, and matching reference fasta file
        #- 2023-12-28: ~ 3.6G fasta files (n = 1124)
        .populate_refs(.DBZ_DATA_DIR = .DBZ_DATA_DIR) |> 

        ## Find mcool files
        #- 2023-12-28: ~ 3.3G mcool files (n = 381)
        .populate_maps(.DBZ_DATA_DIR = .DBZ_DATA_DIR) |> 

        ## Find distance_law files
        #- 2023-12-28: ~ 3.9M distance_law.csv files (n = 348)
        .populate_ps(.DBZ_DATA_DIR = .DBZ_DATA_DIR) |> 

        ## Find pairs files
        #- 2023-12-28: ~  754G pairs files (n = 762)
        .populate_pairs(.DBZ_DATA_DIR = .DBZ_DATA_DIR) |> 

        ## Find macrodomain, DI, insulation, borders and loops files
        .populate_features(.DBZ_DATA_DIR = .DBZ_DATA_DIR) |> 

        ## List all files
        .populate_files(.DBZ_DATA_DIR = .DBZ_DATA_DIR)

}

.init_sqlite <- function(db_path) {

    if (file.exists(db_path)) unlink(db_path)
    db <- DBI::dbConnect(RSQLite::SQLite(), db_path)
    DBI::dbDisconnect(db)
    return(db)

}

.populate_refs <- function(db, .DBZ_DATA_DIR) {

    # REFERENCES sqlite table:
    # |_ sample       <chr>
    # |_ Genus        <chr>
    # |_ species      <chr>
    # |_ isolate      <chr>
    # |_ fasta        <chr>

    dir <- file.path(.DBZ_DATA_DIR, 'ToB')
    fasta_f <- dir |> list.files(pattern = '*.fa$', full.names = TRUE)
    df <- tibble::tibble(fasta = fasta_f) |> 
        dplyr::mutate(sample = stringr::str_replace(fasta, dir, '') |> 
            stringr::str_replace(".fa$", '') |> 
            stringr::str_replace("^/", '')
        ) |> 
        dplyr::mutate(sample2 = sample) |> 
        tidyr::separate_wider_delim(cols = sample2, names = c('Genus', 'species', 'isolate'), delim = '_', too_few = "align_start", too_many = 'merge') |> 
        dplyr::relocate(fasta, .after = isolate)

    db <- RSQLite::dbConnect(db)
    RSQLite::dbWriteTable(db, "REFERENCES", df, overwrite = TRUE)
    RSQLite::dbDisconnect(db)
    return(db)

}

.populate_maps <- function(db, .DBZ_DATA_DIR) {

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
        tidyr::separate_wider_delim(cols = sample, names = c('Genus', 'species', 'isolate'), delim = '_', too_few = "align_start", too_many = 'drop') |> 
        dplyr::mutate(isolate = ifelse(isolate == library, NA, isolate)) |> 
        dplyr::relocate(mcool, .after = library) |> 
        dplyr::left_join(
            dplyr::select(refs, sample, species), 
            y = _, 
            by = "species", 
            relationship = "many-to-many"
        ) |> 
            dplyr::select(-species, -Genus, -isolate) |> 
            tidyr::drop_na(mcool)

    RSQLite::dbWriteTable(db, "MAPS", df, overwrite = TRUE)
    RSQLite::dbDisconnect(db)
    return(db)

}

.populate_ps <- function(db, .DBZ_DATA_DIR) {

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
        tidyr::separate_wider_delim(cols = sample, names = c('Genus', 'species', 'isolate'), delim = '_', too_few = "align_start", too_many = 'drop') |> 
        dplyr::mutate(isolate = ifelse(isolate == library, NA, isolate)) |> 
        dplyr::relocate(ps, .after = library) |> 
        dplyr::left_join(
            dplyr::select(refs, sample, species), 
            y = _, 
            by = "species", 
            relationship = "many-to-many"
        ) |> 
            dplyr::select(-species, -Genus, -isolate) |> 
            tidyr::drop_na(ps)

    RSQLite::dbWriteTable(db, "DISTANCELAW", df, overwrite = TRUE)
    RSQLite::dbDisconnect(db)
    return(db)

}

.populate_pairs <- function(db, .DBZ_DATA_DIR) {

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
        tidyr::separate_wider_delim(cols = sample, names = c('Genus', 'species', 'isolate'), delim = '_', too_few = "align_start", too_many = 'drop') |> 
        dplyr::mutate(isolate = ifelse(isolate == library, NA, isolate)) |> 
        dplyr::relocate(pairs, .after = library) |> 
        dplyr::relocate(file, .after = pairs) |> 
        dplyr::left_join(
            dplyr::select(refs, sample, species), 
            y = _, 
            by = "species", 
            relationship = "many-to-many"
        ) |> 
            dplyr::select(-species, -Genus, -isolate) |> 
            tidyr::drop_na(file)

    RSQLite::dbWriteTable(db, "PAIRS", df, overwrite = TRUE)
    RSQLite::dbDisconnect(db)
    return(db)

}

.populate_features <- function(db, .DBZ_DATA_DIR) {

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
        tidyr::separate_wider_delim(cols = sample, names = c('Genus', 'species', 'isolate'), delim = '_', too_few = "align_start", too_many = 'drop') |> 
        dplyr::mutate(isolate = ifelse(isolate == library, NA, isolate)) |> 
        dplyr::relocate(feature, .after = library) |> 
        dplyr::relocate(file, .after = feature) |> 
        dplyr::left_join(
            dplyr::select(refs, sample, species), 
            y = _, 
            by = "species", 
            relationship = "many-to-many"
        ) |> 
            dplyr::select(-species, -Genus, -isolate) |> 
            tidyr::drop_na(file)

    dir <- file.path(.DBZ_DATA_DIR, 'DI')
    DI_f <- dir |> list.files(pattern = '*.bed$', full.names = TRUE)
    df_DI <- tibble::tibble(feature = "DI", file = DI_f) |> 
        dplyr::mutate(sample = stringr::str_replace(file, dir, '') |> 
            stringr::str_replace("_DI.bed$", '') |> 
            stringr::str_replace("^/", '')
        ) |> 
        dplyr::mutate(library = stringr::str_replace(sample, ".*_", '')) |>
        tidyr::separate_wider_delim(cols = sample, names = c('Genus', 'species', 'isolate'), delim = '_', too_few = "align_start", too_many = 'drop') |> 
        dplyr::mutate(isolate = ifelse(isolate == library, NA, isolate)) |> 
        dplyr::relocate(feature, .after = library) |> 
        dplyr::relocate(file, .after = feature) |> 
        dplyr::left_join(
            dplyr::select(refs, sample, species), 
            y = _, 
            by = "species", 
            relationship = "many-to-many"
        ) |> 
            dplyr::select(-species, -Genus, -isolate) |> 
            tidyr::drop_na(feature)

    dir <- file.path(.DBZ_DATA_DIR, 'insulation')
    insulation_f <- dir |> list.files(pattern = '*.bed$', full.names = TRUE)
    df_insul <- tibble::tibble(feature = "insulation", file = insulation_f) |> 
        dplyr::mutate(sample = stringr::str_replace(file, dir, '') |> 
            stringr::str_replace("_insulation.bed$", '') |> 
            stringr::str_replace("^/", '')
        ) |> 
        dplyr::mutate(library = stringr::str_replace(sample, ".*_", '')) |>
        tidyr::separate_wider_delim(cols = sample, names = c('Genus', 'species', 'isolate'), delim = '_', too_few = "align_start", too_many = 'drop') |> 
        dplyr::mutate(isolate = ifelse(isolate == library, NA, isolate)) |> 
        dplyr::relocate(feature, .after = library) |> 
        dplyr::relocate(file, .after = feature) |> 
        dplyr::left_join(
            dplyr::select(refs, sample, species), 
            y = _, 
            by = "species", 
            relationship = "many-to-many"
        ) |> 
            dplyr::select(-species, -Genus, -isolate) |> 
            tidyr::drop_na(feature)

    dir <- file.path(.DBZ_DATA_DIR, 'borders')
    borders_f <- dir |> list.files(pattern = '*.bed$', full.names = TRUE)
    df_borders <- tibble::tibble(feature = "borders", file = borders_f) |> 
        dplyr::mutate(sample = stringr::str_replace(file, dir, '') |> 
            stringr::str_replace("_borders.bed$", '') |> 
            stringr::str_replace("^/", '')
        ) |> 
        dplyr::mutate(library = stringr::str_replace(sample, ".*_", '')) |>
        tidyr::separate_wider_delim(cols = sample, names = c('Genus', 'species', 'isolate'), delim = '_', too_few = "align_start", too_many = 'drop') |> 
        dplyr::mutate(isolate = ifelse(isolate == library, NA, isolate)) |> 
        dplyr::relocate(feature, .after = library) |> 
        dplyr::relocate(file, .after = feature) |> 
        dplyr::left_join(
            dplyr::select(refs, sample, species), 
            y = _, 
            by = "species", 
            relationship = "many-to-many"
        ) |> 
            dplyr::select(-species, -Genus, -isolate) |> 
            tidyr::drop_na(feature)

    dir <- file.path(.DBZ_DATA_DIR, 'chromosight')
    loops_f <- dir |> list.files(pattern = '*.tsv$', full.names = TRUE)
    df_loops <- tibble::tibble(feature = "loops", file = loops_f) |> 
        dplyr::mutate(sample = stringr::str_replace(file, dir, '') |> 
            stringr::str_replace("_loops.tsv$", '') |> 
            stringr::str_replace("^/", '')
        ) |> 
        dplyr::mutate(library = stringr::str_replace(sample, ".*_", '')) |>
        tidyr::separate_wider_delim(cols = sample, names = c('Genus', 'species', 'isolate'), delim = '_', too_few = "align_start", too_many = 'drop') |> 
        dplyr::mutate(isolate = ifelse(isolate == library, NA, isolate)) |> 
        dplyr::relocate(feature, .after = library) |> 
        dplyr::relocate(file, .after = feature) |> 
        dplyr::left_join(
            dplyr::select(refs, sample, species), 
            y = _, 
            by = "species", 
            relationship = "many-to-many"
        ) |> 
            dplyr::select(-species, -Genus, -isolate) |> 
            tidyr::drop_na(feature)

    df <- rbind(df_macro, df_DI, df_insul, df_borders, df_loops)
    RSQLite::dbWriteTable(db, "FEATURES", df, overwrite = TRUE)
    RSQLite::dbDisconnect(db)
    return(db)

}

.populate_files <- function(db, .DBZ_DATA_DIR) {

    # FILES sqlite table:
    # |_ file      <chr>
    # |_ hash      <chr>

    # Available features: macrodomains, DI, insulations, borders, chromosight loops
    db <- RSQLite::dbConnect(db)
    refs <- dplyr::tbl(db, "REFERENCES") |> dplyr::collect()

    ref_f <- dplyr::tbl(db, "REFERENCES") |> 
        dplyr::collect() |> 
        dplyr::pull(fasta)
    map_f <- dplyr::tbl(db, "MAPS") |> 
        dplyr::collect() |> 
        dplyr::pull(mcool)
    pairs_f <- dplyr::tbl(db, "PAIRS") |> 
        dplyr::collect() |> 
        dplyr::pull(file)
    features_f <- dplyr::tbl(db, "FEATURES") |> 
        dplyr::collect() |> 
        dplyr::pull(file)
    files <- tibble::tibble(
        file = c(ref_f, map_f, pairs_f, features_f)
    ) |> 
        dplyr::rowwise() |>
        dplyr::mutate(
            hash = paste(sample(c(letters, 0:9), 12), collapse = "")
        )

    RSQLite::dbWriteTable(db, "FILES", files, overwrite = TRUE)
    RSQLite::dbDisconnect(db)
    return(db)

}
