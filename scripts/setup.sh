#!/bin/bash

# File setupMyEth2Node.sh - A script to quickly setup ETH2.0
# Author: MAX VUONG

set -eu

# Install Docker
function install_docker() { 
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sudo sh /tmp/get-docker.sh
  
  sudo usermod -aG docker $USER
  newgrp docker
  
  sudo systemctl enable docker
}

# Uninstall Docker
function uninstall_docker() { 
  sudo apt-get purge -y docker-ce docker-ce-cli containerd.io
  sudo rm -rf /var/lib/docker
}

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

# # Run backup for all
# function backup_all() {
  
# }

# Main function to install all necessary package to support the node
function install_all() {
  # Update & Upgrade to latest
  sudo apt-get update && sudo apt-get upgrade
  
  # Install docker
  install_docker

  # Install independent packages
  install_package vim
  install_package git-all
  install_package prometheus
  install_package prometheus-node-exporter
  install_package golang
  install_package zip
  install_package unzip
  install_package build-essential
  install_package python3-venv
  install_package python3-pip
  
  # # Define setup directories
  # mkdir -p $HOME/{.eth2,.eth2stats,.eth2validators,.ethereum,.password,logs,prysm/configs}
  # mkdir -p /etc/ethereum
  # mkdir -p /home/prometheus/node-exporter
  
  # # Create files
  # touch $HOME/.password/password.txt
  # touch $HOME/logs/{beacon,validator,slasher}.log
  
  # # Clone configs repo
  # if [! -d $HOME/SetupUI ]
  # then
    # git clone https://github.com/xuyenvuong/pi4-pos-setup.git $HOME/SetupUI
  # else
    # cd $HOME/SetupUI
    # git pull origin master
    # cd $HOME
  # fi
  
  install_docker
}

function uninstall_all() {
  # TODO: backup_all
  # backup_all

  # Uninstall docker
  uninstall_docker
  
  # Uninstall independent packages
  uninstall_package vim
  uninstall_package git-all
  uninstall_package prometheus
  uninstall_package prometheus-node-exporter
  uninstall_package golang
  uninstall_package zip
  uninstall_package unzip
  uninstall_package build-essential
  uninstall_package python3-venv
  uninstall_package python3-pip 
}

# function setup() {
  # echo "Installing....."
  
  # exit 0
  
  # # Run docker  
# }

function help() {
  echo "Help..."
}


case $1 in
  install) install_all;;
  uninstall) uninstall_all;;
  # setup) setup;;
  help) help;;
  *)
    echo "Task '$1' is not found!"
    echo "Please use 'setup.sh help' for more info."
    exit 1
    ;;
esac