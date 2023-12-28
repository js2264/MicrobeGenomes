.get_metrics <- function(species, db) {
    NULL
}

.get_data <- function(species, db) {
    NULL
}

.get_map <- function(species, db) {
    NULL
}

.get_features <- function(species, db) {
    NULL
}

.get_aggr_plot <- function(species, db) {
    NULL
}




.get_ps <- function(species, db) {
    ps_f <- dplyr::tbl(db, "DISTANCELAW") |> 
        dplyr::collect() |> 
        dplyr::filter(sample == species) |> 
        dplyr::pull(ps)
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
