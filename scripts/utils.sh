#!/bin/bash
# utils.sh - A script to provide quick maintenance work
# Author: Max Vuong
# Last update: 20260601

: <<'COMMENT_BLOCK'
Instructions to run the utils script:

Run:
> bash <(curl -s https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/refs/heads/master/scripts/utils.sh)

COMMENT_BLOCK

#-------------------------------------------------------------------------------------------#

set -eu

# # Install package
# function install_package() {
#   local dpkg_name=$1

#   if [ $(dpkg-query -W -f='${Status}' $dpkg_name 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
#     echo "Installing: $dpkg_name"
#     sudo apt install -y $dpkg_name
#   fi
# }

source <(curl -s https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/refs/heads/master/scripts/lib.sh)

#-------------------------------------------------------------------------------------------#

# Perform prune history
function perform_prune_history() {
  install_package jq
  # Prune geth  
  # /usr/local/bin/geth prune-history --history.chain postmerge --datadir /mnt/ssd2tb/chaindata --datadir.ancient /mnt/ssd4tb/ancientdb

  data_dir=$(cat /etc/ethereum/geth.conf | grep 'datadir ')
  data_dir_ancient=$(cat /etc/ethereum/geth.conf | grep 'datadir.ancient ')

  if [ -e /usr/local/bin/geth ]; then
    sudo systemctl stop prysm-beacon.service
    sudo systemctl stop geth.service

    if [ -z "$data_dir_ancient" ]; then
      /usr/local/bin/geth prune-history --history.chain postmerge $data_dir
    else
      /usr/local/bin/geth prune-history --history.chain postmerge $data_dir  $data_dir_ancient
    fi

    sudo systemctl start prysm-beacon.service
    sudo systemctl start geth.service

    echo "Done: Prunning history is completed."
  fi
}

#-------------------------------------------------------------------------------------------#
# Utils prompt
#-------------------------------------------------------------------------------------------#

PS3='Please enter your command choice: '
options=("Prune History" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Prune History")            
            echo "Installing $opt"
            perform_prune_history
            ;;
        "Quit")
            echo "Good bye!"
            break
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done

source ~/.bashrc
