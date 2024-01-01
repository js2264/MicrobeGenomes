To initiate the app:

1. Update the `inst/extdata/processed_files.csv` file to list all available files 
2. Sync `./data` <- remote `sftpcampus`
3. Sync `s3://mgc-shinyapp/data` <- `./data`: `aws s3 sync data s3://mgc-shinyapp/data`
4. Sync repo on `EC2:/MicrobeGenomes`: `cd ~/MicrobeGenomes && git pull`
5. Make sure the S3 bucket is mounted in EC2: `sudo s3fs mgc-shinyapp /mnt/ -o passwd_file=~/.passwd-s3fs -o umask=022 -o allow_other`
6. Restart Shiny server: `sudo systemctl reload shiny-server`

Read files in `inst/scripts/aws-setup` for more details. 
