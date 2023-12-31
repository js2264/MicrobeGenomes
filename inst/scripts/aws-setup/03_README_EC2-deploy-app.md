Guide: https://www.charlesbordet.com/en/guide-shiny-aws/#2-how-to-deploy-your-app-on-the-server

# Install R and app dependencies

- Connect to remote AWS machine using the `Public IPv4 address`

```shell
ssh -i ~/.ssh/myaws.pem ubuntu@35.181.170.86
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
cd ~
git clone https://github.com/js2264/MicrobeGenomes.git
```

- Install app dependencies

```r
install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))
pak::local_install_deps('~/MicrobeGenomes')
```

# Set up shiny-server

- Install shiny-server

```shell
sudo R -e "install.packages('shiny')"
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.21.1012-amd64.deb
sudo gdebi shiny-server-1.5.21.1012-amd64.deb
```

- Set up security ports

In AWS EC2 instance page, go to `Security` tab
Edit the `Security Group` for inbound rules
Add a rule: `Custom TCP`, port `3838`, source `0.0.0.0/0` 

- Symlink the app repo to `/srv/shiny-server/`

```shell
sudo chmod 777 ~/MicrobeGenomes
sudo chmod 777 /srv/shiny-server
sudo chmod 777 /etc/shiny-server
sudo ln -s ~/MicrobeGenomes /srv/shiny-server
```

- Keep all shiny-server logs 

```shell
sudo vim /etc/shiny-server/shiny-server.conf ## change to `run_as ubuntu;`
sudo vim /etc/shiny-server/shiny-server.conf ## Add `preserve_logs true;`
sudo systemctl reload shiny-server
```

# Deploy app 

```r
R -e "options('shiny.port'= 3838, shiny.host='0.0.0.0') ; pkgload::load_all('~/MicrobeGenomes') ; MicrobeGenomes::run_app()"
```
