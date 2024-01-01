Guide: https://www.bdrsuite.com/blog/how-to-mount-s3-bucket-in-aws-ec2-using-s3fs/

# Update the list of processed files present in remote data

- Filter `metadata.csv` to only retain `WT` samples (2023-12-29: 70 samples)

```shell
head -n1 DBZ/DBZ_workflow/config/metadata.csv > tmp.csv
grep ,WT, DBZ/DBZ_workflow/config/metadata.csv >> tmp.csv
cat tmp.csv | cut -d, -f1,2,3,5,6,7,8,14,19,20,21,22,23 | uniq > samples.csv
rm tmp.csv
```

- Find all existing processed files for all samples (2023-12-29: 504 files found on `sftpcampus:~/rsg_fast/abignaud/DBZ/results/`)

```r
library(tidyverse)
samples <- readr::read_csv('samples.csv') |> mutate(Genus = str_to_title(Genus)) 
files <- map_dfr(
    c("assembly", "cool", "distance_law", "filtered_pairs", "pairs", "macrodomains", "DI", "insulation", "borders", "chromosight"),
    function(type) {
        folder <- case_when(
            type == 'assembly' ~ "ref", 
            type == 'cool' ~ "results/cool", 
            type == 'distance_law' ~ "results/distance_law", 
            type == 'filtered_pairs' ~ "results/distance_law", 
            type == 'pairs' ~ "results/pairs", 
            type == 'macrodomains' ~ "results/macrodomains", 
            type == 'DI' ~ "results/DI", 
            type == 'insulation' ~ "results/insulation", 
            type == 'borders' ~ "results/borders", 
            type == 'chromosight' ~ "results/chromosight", 
            .default = NA
        )
        ext <- case_when(
            type == 'assembly' ~ ".fa", 
            type == 'cool' ~ ".mcool", 
            type == 'distance_law' ~ "_distance_law.csv", 
            type == 'filtered_pairs' ~ "_filtered.pairs", 
            type == 'pairs' ~ ".pairs", 
            type == 'macrodomains' ~ "_macrodomains.bed", 
            type == 'DI' ~ "_DI.bed", 
            type == 'insulation' ~ "_insulation.bed", 
            type == 'borders' ~ "_borders.bed", 
            type == 'chromosight' ~ "_loops.tsv", 
            .default = NA
        )
        files <- list.files(file.path('DBZ', type))
        group_by(samples, Genus, Species, Strain) |> 
            group_modify(~ {
                file <- file.path(folder, paste0(.x$Fasta, "_", .x$Fastq, ext))
                if (type == 'assembly') file <- file.path(folder, paste0(.x$Fasta, ".fa"))
                tibble(.x, file = file, type = type) 
            })
    }
) |> 
    group_by(Genus, Species, Strain) |> 
    arrange(Genus, Species, Strain)
# writeLines(list.files('~/rsg_fast/abignaud/DBZ/', recursive = TRUE), 'existing_files.txt') ## on sftpcampus
existing_files <- readLines("existing_files.txt")
files <- filter(files, file %in% existing_files)
files |> readr::write_csv('inst/extdata/processed_files.csv')
```

# Sync the data folder <- remote data from `sftpcampus` 

```shell
cut -f14 -d, inst/extdata/processed_files.csv | sed '1d' | sed 's,\s.*,,' > files_to_dl.txt
rsync --progress --verbose --files-from files_to_dl.txt sftpcampus:rsg_fast/abignaud/DBZ/ data/
mv data/results/* data/
rm data/results/
```

# Create an S3 bucket 

Default parameters, open access

# Sync the S3 bucket <- local data folder

```shell
aws configure
# Enter key details here... 
aws s3 sync data s3://mgc-shinyapp/data
```
