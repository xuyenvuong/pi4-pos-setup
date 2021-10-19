#!/bin/bash
# prysm_upgrade.sh - A script to quickly upgrade Prysm
# Run: ./prysm_upgrade.sh
# Author: Max Vuong
# Date: 10/18/2021

# Go to home dir
cd

# Download & Install prysm beacon
read -p "Do you want to install and run latest Prysm Beacon version (Y/y)? " -n 1

if [[ $REPLY =~ ^[Yy]$ ]]
  then
    bash $HOME/prysm/prysm.sh beacon-chain --download-only
	
    sudo systemctl restart prysm-beacon.service
	
    echo "Successfully installed Prysm beacon-chain"	
  else
    echo " ABORT installing Prysm Beacon."
fi

# Download & Install prysm validator
read -p "Do you want to install and run latest Prysm Validator version (Y/y)? " -n 1

if [[ $REPLY =~ ^[Yy]$ ]]
  then
    bash $HOME/prysm/prysm.sh validator --download-only
	
    sudo systemctl restart prysm-validator.service
	
    echo "Successfully installed Prysm validator"	
  else
    echo " ABORT installing Prysm Validator."
fi

echo "Done!"

# EOF