Guide: https://www.charlesbordet.com/en/guide-shiny-aws/#2-how-to-deploy-your-app-on-the-server

# Create an EC2 instance

- AMI: `ami-01d21b7be69801c2f`
- Type: `t2-large`
- Key: `myaws`
- Security: NA
- Storage: `30Gb`

# Install R and app dependencies

- Connect to remote AWS machine 

```shell
ssh -i ~/.ssh/myaws.pem ubuntu@ec2-35-181-170-86.eu-west-3.compute.amazonaws.com
```

- Install R (`https://docs.posit.co/resources/install-r/#__tabbed_1_4`)

```shell
sudo apt-get update -y
sudo apt-get install gdebi-core -y
export R_VERSION=4.3.2
curl -O https://cdn.rstudio.com/r/ubuntu-2204/pkgs/r-${R_VERSION}_1_amd64.deb
sudo gdebi r-${R_VERSION}_1_amd64.deb 
sudo ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R
```

- Clone app repo 

```shell
git clone https://github.com/js2264/MicrobeGenomes.git
```

- Install app dependencies

```r
install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))
pak::local_install_deps('./MicrobeGenomes')
```

# Set up shiny-server

- Install shiny-server

```shell
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.21.1012-amd64.deb
sudo gdebi shiny-server-1.5.21.1012-amd64.deb
```

- Set up security ports

In AWS EC2 instance page, go to `Security` tab
Edit the `Security Group` for inbound rules
Add a rule: `Custom TCP`, port `3838`, source `0.0.0.0/0` 

- Symlink the app repo to `/srv/shiny-server/`

```shell
sudo ln -s MicrobeGenomes /srv/shiny-server/
```

- Keep all shiny-server logs 

```shell
sudo echo "preserve_logs true;" >> /etc/shiny-server/shiny-server.conf
sudo systemctl reload shiny-server
```

# Deploy app 

```r
options('shiny.port'=80,shiny.host='0.0.0.0')
pkgload::load_all('~/MicrobeGenomes')
MicrobeGenomes::run_app()
```
