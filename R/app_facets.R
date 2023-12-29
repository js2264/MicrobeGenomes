.get_metrics <- function(species, db) {
    n <- species
    db <- RSQLite::dbConnect(db)
    ref <- dplyr::tbl(db, "REFERENCES") |> 
        dplyr::collect() |> 
        dplyr::filter(n == sample) 
    RSQLite::dbDisconnect(db)
    seqs <- Biostrings::readDNAStringSet(ref$fasta)
    metrics <- tibble::tribble(
        ~key,                   ~value, 
        "Name",                 with(ref, glue::glue("{Genus} {species} (isolate {isolate})")), 
        # "Taxon id",             "", 
        "Total genome size",    format(sum(lengths(seqs)), big.mark = ",", scientific = FALSE), 
        "Number of contigs",    as.character(length(seqs)), 
        "Contig N50",           format(Biostrings::N50(lengths(seqs)), big.mark = ",", scientific = FALSE), 
        "GC percent",           sprintf("%0.1f%%", mean(Biostrings::letterFrequency(seqs, letters = 'GC', as.prob = TRUE)) * 100), 
    )
    contigs <- tibble::tibble(
        Contig = names(seqs), 
        Length = lengths(seqs)
    )
    list(metrics, contigs)
}

.get_map <- function(species, db) {
    db <- RSQLite::dbConnect(db)
    map_f <- dplyr::tbl(db, "MAPS") |> 
        dplyr::collect() |> 
        dplyr::filter(sample == species) |> 
        dplyr::pull(mcool)
    RSQLite::dbDisconnect(db)
    if (length(map_f) > 0) {
        withProgress(message = "Crunching data...", value = 0, {
            incProgress(0.1, detail = "Fetching contact map")
            cf <- HiCExperiment::CoolFile(map_f[1]) 
            incProgress(0.3, detail = "Importing contacts")
            hc <- HiCExperiment::import(cf, resolution = 2000)
            incProgress(0.6, detail = "Plotting contact map")
            p <- HiContacts::plotMatrix(hc)
            incProgress(0.9, detail = "Wrapping up")
            p
        })

    } else {
        return(NULL)
    }
}

.get_ps <- function(species, db) {
    db <- RSQLite::dbConnect(db)
    ps_f <- dplyr::tbl(db, "DISTANCELAW") |> 
        dplyr::collect() |> 
        dplyr::filter(sample == species) |> 
        dplyr::pull(ps)
    RSQLite::dbDisconnect(db)
    if (length(ps_f) > 0) {
        df <- read.csv(ps_f[1]) 
        ggplot2::ggplot(df, ggplot2::aes(x = binned_distance, y = norm_p)) +
            ggplot2::scale_y_log10(
                limits = c(1e-07, 2e-05), 
                expand = c(0, 0), 
                breaks = scales::trans_breaks("log10", function(x) 10^x),
                labels = scales::trans_format("log10", scales::math_format(10^.x))
            ) + 
            ggplot2::scale_x_log10(
                limits = c(5000, 499000), 
                expand = c(0, 0), 
                breaks = c(1, 10, 100, 1000, 10000, 1e+05, 1e+06, 1e+07, 1e+08, 1e+09, 1e+10),
                labels = c('1', '10', '100', '1kb', '10kb', '100kb', '1Mb', '10Mb', '100Mb', '1Gb', '10Gb')
            ) + 
            ggplot2::geom_line() + 
            ggplot2::theme_minimal() + 
            ggplot2::theme(panel.border = ggplot2::element_rect(fill = NA)) + 
            ggplot2::theme(panel.grid.minor = ggplot2::element_blank()) +
            ggplot2::annotation_logticks() + 
            ggplot2::labs(x = "Genomic distance", y = "Contact frequency")
    } else {
        return(NULL)
    }
}

.get_data <- function(species, db) {
    n <- species
    db <- RSQLite::dbConnect(db)
    all_files <- dplyr::tbl(db, "FILES") |> 
        dplyr::collect()
    ref_f <- dplyr::tbl(db, "REFERENCES") |> 
        dplyr::collect() |> 
        dplyr::filter(n == sample) |> 
        dplyr::pull(fasta)
    map_f <- dplyr::tbl(db, "MAPS") |> 
        dplyr::collect() |> 
        dplyr::filter(sample == species) |> 
        dplyr::pull(mcool)
    pairs_f <- dplyr::tbl(db, "PAIRS") |> 
        dplyr::collect() |> 
        dplyr::filter(sample == species) |> 
        dplyr::pull(file)
    RSQLite::dbDisconnect(db)
    files <- tibble::tibble(
        Type = c(
            rep("assembly", length(ref_f)), 
            rep("contact map", length(map_f)), 
            rep("pairs", length(pairs_f))
        ), 
        File = c(ref_f, map_f, pairs_f)
    ) |> 
        dplyr::left_join(all_files, by = c("File" = "file"))
    files$Link <- makeButtons(files$hash)
    dplyr::relocate(files, Link)
}

.get_features <- function(species, db) {
    n <- species
    db <- RSQLite::dbConnect(db)
    all_files <- dplyr::tbl(db, "FILES") |> 
        dplyr::collect()
    features_f <- dplyr::tbl(db, "FEATURES") |> 
        dplyr::collect() |> 
        dplyr::filter(sample == species)
    RSQLite::dbDisconnect(db)
    files <- tibble::tibble(
        Type = features_f$feature, 
        File = features_f$file
    ) |> dplyr::left_join(all_files, by = c("File" = "file"))
    files$Link <- makeButtons(files$hash)
    dplyr::relocate(files, Link)
}

.get_aggr_plot <- function(species, db) {
    NULL
}
