Guide: https://www.charlesbordet.com/en/guide-shiny-aws/#2-how-to-deploy-your-app-on-the-server

# Create an EC2 instance

- AMI: `ami-01d21b7be69801c2f`
- Type: `t2-large`
- Key: `myaws`
- Security: NA
- Storage: `30Gb`

# Install `s3fs` on EC2 instance 

```shell
sudo apt-get update -y
sudo apt-get install awscli -y
sudo apt-get install s3fs -y
```

# Create IAM policy for S3 access

1. Create a new `user` in the `IAM` Service: 

- Use case: `S3`
- Policy `AmazonS3FullAccess`

1. Create an access key for this user for CLI

2. Store this access key in the EC2

```shell
echo “YOUR_ACCESS_KEY_ID:YOUR_SECRET_ACCESS_KEY” > ~/.passwd-s3fs
chmod 600 ~/.passwd-s3fs
```

# Mount `S3` 

- Sync EC2 and S3 

```shell
sudo s3fs mgc-shinyapp /mnt/ -o passwd_file=~/.passwd-s3fs -o umask=022 -o allow_other
# sudo fusermount -u /mnt/
```
