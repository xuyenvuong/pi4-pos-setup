#!/bin/bash
# setup.sh - A script to quickly setup ETH2.0 Prysm node
# Author: Max Vuong

set -eu

# Install package
function install_package() {
  local dpkg_name=$1

  if [ $(dpkg-query -W -f='${Status}' $dpkg_name 2>/dev/null | grep -c "ok installed") -eq 0 ]
  then
    echo "Installing: $dpkg_name"
    sudo apt install -y $dpkg_name
  fi
}

# Uninstall package
function uninstall_package() {
  local dpkg_name=$1

  if [ $(dpkg-query -W -f='${Status}' $dpkg_name 2>/dev/null | grep -c "ok installed") -eq 1 ]
  then
    echo "Uninstalling: $dpkg_name"
	sudo apt purge -y $dpkg_name
  fi
}
#-------------------------------------------------------------------------------------------#
# Main function to install all necessary package to support the node
function install_essential() {
  # Update & Upgrade to latest
  sudo apt-get update && sudo apt-get upgrade
  
  # Install docker
  install_docker

  # Install independent packages
  install_package vim
  install_package git-all
  install_package zip
  install_package unzip
  install_package build-essential
  
  # Install Prometheus
  install_prometheus
  
  # Install Golang
  install_package golang
  
  # Install Python
  install_python
  
  # Install Grafana
  install_grafana
  
  # Install GETH
  install_geth
}

# Install Docker
function install_docker() {
  sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  
  sudo add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  
  sudo groupadd docker
  sudo usermod -aG docker $USER
  newgrp docker
  
  sudo systemctl enable docker
}

# Install Prometheus
function install_prometheus() {
  if [ $(dpkg-query -W -f='${Status}' prometheus 2>/dev/null | grep -c "ok installed") -eq 0 ]
  then
    echo "Installing: Prometheus"
	sudo useradd -m prometheus
	sudo chown -R prometheus:prometheus /home/prometheus/
    install_package prometheus
    install_package prometheus-node-exporter
  fi
}

# Install Python
function install_python() {
  if [ $(dpkg-query -W -f='${Status}' python3 2>/dev/null | grep -c "ok installed") -eq 0 ]
  then
    echo "Installing: Python"
    install_package software-properties-common
    sudo add-apt-repository ppa:deadsnakes/ppa
    sudo apt-get update
    install_package python3.8
    install_package python3-venv
    install_package python3-pip
  fi 
}

# Install Grafana
function install_grafana() {
  if [ $(dpkg-query -W -f='${Status}' grafana 2>/dev/null | grep -c "ok installed") -eq 0 ]
  then
    echo "Installing: Grafana"
    install_package apt-transport-https
    install_package software-properties-common
	wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
    echo "deb https://packages.grafana.com/enterprise/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
    sudo apt-get update
    install_package grafana-enterprise
  fi 
}

# Install GETH
function install_geth() {
  if [ $(dpkg-query -W -f='${Status}' geth 2>/dev/null | grep -c "ok installed") -eq 0 ]
  then
    echo "Installing: GETH"
    sudo add-apt-repository -y ppa:ethereum/ethereum
    sudo apt-get update
    install_package ethereum
  fi 
}

#-------------------------------------------------------------------------------------------#
# Upgrade all
function upgrade_all() {
  echo "Upgrading...."
  
  # Update & Upgrade to latest
  sudo apt-get update && sudo apt-get upgrade
  
  # Pull latest pi4-pos-setup.git repo
  if [ ! -d $HOME/pos-setup ]
  then
    git clone https://github.com/xuyenvuong/pi4-pos-setup.git $HOME/pos-setup
  else
    cd $HOME/pos-setup
    git pull origin master
    cd $HOME
  fi  
}

#-------------------------------------------------------------------------------------------#
# Initialize pos setup: important files/directories in order to run the PoS node
function build_pos() {   
  # Define setup directories
  mkdir -p $HOME/{.eth2,.eth2stats,.eth2validators,.ethereum,.password,logs,prysm,prysm/configs}
  sudo mkdir -p /etc/ethereum
  sudo mkdir -p /home/prometheus/node-exporter
  
  # Create files
  touch $HOME/.password/password.txt
  touch $HOME/logs/{beacon,validator,slasher}.log
  
  # Clone pi4-pos-setup.git repo
  if [ ! -d $HOME/pos-setup ]
  then
    git clone https://github.com/xuyenvuong/pi4-pos-setup.git $HOME/pos-setup
  fi
  
  # Setup prysm script
  curl https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh --output $HOME/prysm/prysm.sh && chmod +x $HOME/prysm/prysm.sh  
}

#-------------------------------------------------------------------------------------------#
# Run backup for all
function backup_all() {
  echo "Backing up...."
}

#-------------------------------------------------------------------------------------------#
# Verify setup 
function verify() {
  echo "Verifying...."
}

#-------------------------------------------------------------------------------------------#
# Display help
function help() {
  echo "Help..."
}


#-------------------------------------------------------------------------------------------#
case $1 in
  -i|--install)    
    install_essential 
	;;  
  -u|--upgrade)
    upgrade_all
	;;
  -b|--build)
    build_pos
	;;  
  -s|--save)
    backup_all
	;;  
  -h|--help)
    help
	;;
  *)
    echo "Task '$1' is not found!"
    echo "Please use 'setup.sh help' for more info."
    exit 1
    ;;
esac