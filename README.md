1. Read files in `inst/scripts/aws-setup`
2. Update the `inst/extdata/processed_files.csv` file to list all available files 
3. Make sure `processed_files` and `s3_mounting` arguments in `R/global.R` are correctly set for EC2 hosting
4. Sync `./data` <- remote `sftpcampus`
5. Sync `s3://mgc-shinyapp/data` <- `./data`
6. `git pull` on `EC2:/MicrobeGenomes`
7. Restart Shiny server: `sudo systemctl reload shiny-server`
