#!/bin/bash
# setup.sh - A script to quickly setup ETH2.0 Prysm node
# Author: Max Vuong

set -eu

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

# Uninstall Docker
function uninstall_docker() { 
  sudo apt-get purge -y docker-ce docker-ce-cli containerd.io 
  sudo apt-get purge -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
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
  install_package prometheus
  install_package prometheus-node-exporter
  install_package golang
  install_package zip
  install_package unzip
  install_package build-essential
  install_package python3-venv
  install_package python3-pip
}

# Install Python
function install_python() { 
  if [ $(dpkg-query -W -f='${Status}' python3 2>/dev/null | grep -c "ok installed") -eq 0 ]
  then
    wget -O /tmp/python.tgz https://www.python.org/ftp/python/3.8.5/Python-3.8.5.tgz
    mkdir -p /tmp/Python
    tar -C /tmp/Python --strip-components 1 -xvf /tmp/python.tgz
	
	cd /tmp/Python
	
	./configure --enable-optimizations
	sudo make altinstall
	
	python3 --version
	cd
  fi
}

# Install Grafana
function install_grafana() {
  if [ $(dpkg-query -W -f='${Status}' grafana 2>/dev/null | grep -c "ok installed") -eq 0 ]
  then
    wget -O /tmp/grafana.deb https://dl.grafana.com/oss/release/grafana_7.0.3_arm64.deb
	sudo dpkg --force-all -i /tmp/grafana.deb
	rm /tmp/grafana.deb
  fi 
}

#-------------------------------------------------------------------------------------------#
# Purge all installed packages and their dependencies
function uninstall_all() {
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

  # Remove the rest
  sudo apt autoremove -y 
}

# Uninstall Python
function uninstall_python() {
  # TODO
  echo "TODO: Uninstalling Python..."
}

# Uninstall Grafana
function uninstall_grafana() {
  sudo dpkg –-remove grafana
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
# Tear down files/directories used for PoS
function teardown() {
  echo "Tearing down now..."
  # Remove setup directories
  rm -rf $HOME/{.eth2,.eth2stats,.eth2validators,.ethereum,.password,logs,prysm/configs,prysm}
  sudo rm -rf /etc/ethereum
  sudo rm -rf /home/prometheus
  
  # Clone pos-setup repo
  rm -rf $HOME/pos-setup
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
function install_route() {
  local opt=$1
  
  case $opt in
    essential)
	  echo "Essential ...."
	  ;; #install_essential;;
	python3)
	  echo "Python3 ...."
	  ;; #install_python;;
	grafana)
	  echo "Grafana ...."
	  ;; #install_python;;
	*)
	  echo "Option '$1' is not found!"
      echo "Please use 'setup.sh help' for more info."
	  exit 1;;
  esac
}


#-------------------------------------------------------------------------------------------#
case $1 in
  -i|--install) 
    install_route $2
	;;  
  uninstall)
    uninstall_all
	;;
  upgrade)
    upgrade_all
	;;
  build)
    build_pos
	;; 
  teardown)
    teardown
	;; # Dev mode: Must remove when go live
  
  backup)
    backup_all
	;;
  verify)
    verify
	;;
  
  help)
    help
	;;
  *)
    echo "Task '$1' is not found!"
    echo "Please use 'setup.sh help' for more info."
    exit 1
    ;;
esac