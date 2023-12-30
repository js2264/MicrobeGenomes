Guide: https://www.bdrsuite.com/blog/how-to-mount-s3-bucket-in-aws-ec2-using-s3fs/

# Create an S3 bucket 

Default parameters, open access


# Fill the S3 bucket with important data 

Drag-n-drop `DBZ` folder

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

# Automated mounting `S3` 

```shell
sudo vim /etc/fstab
# Add the following line at the end
# s3fs#mgc-shinyapp /mnt/ fuse _netdev,iam_role=<iam-role-name>,allow_other 0 0
```

