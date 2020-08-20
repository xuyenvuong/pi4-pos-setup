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
}

# Uninstall Docker
function uninstall_docker() { 
  sudo apt-get purge docker-ce docker-ce-cli containerd.io
  sudo rm -rf /var/lib/docker
}

function install() {
  echo "Install....."
  # exit 0
  
  # # Update & Upgrade to latest
  # sudo apt-get update && sudo apt-get upgrade

  # # Install independent packages
  # install_package vim
  # install_package git-all
  # install_package prometheus
  # install_package prometheus-node-exporter
  # install_package golang
  # install_package zip
  # install_package unzip
  # install_package build-essential
  # install_package python3-venv
  # install_package python3-pip
  
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

function setup() {
  echo "Install....."
  exit 0
  
  # Run docker
  sudo systemctl daemon-reload
  sudo systemctl enable docker
  sudo systemctl restart docker.service
  
  
}

function uninstall() {
  echo "Uninstall....."
  uninstall_docker
}

function help() {
  echo "Help..."
}


case $1 in
  install) install;;
  # setup) setup;;
  uninstall) uninstall;;
  help) help;;
  *)
    echo "Task '$1' is not found!"
    echo "Please use 'setup.sh help' for more info."
    exit 1
    ;;
esac