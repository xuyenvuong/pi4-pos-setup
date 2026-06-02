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

source <(curl -s https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/refs/heads/master/scripts/lib.sh)

#-------------------------------------------------------------------------------------------#

# Perform geth prune history
function perform_geth_prune_history() {  
  # Prune geth  
  # /usr/local/bin/geth prune-history --history.chain postmerge --datadir /mnt/ssd2tb/chaindata --datadir.ancient /mnt/ssd4tb/ancientdb

  data_dir=$(cat /etc/ethereum/geth.conf | grep 'datadir ')  

  if [ -e /usr/local/bin/geth ]; then
    sudo systemctl stop prysm-beacon.service
    sudo systemctl stop geth.service

    if [ -z "$(cat /etc/ethereum/geth.conf | grep 'datadir.ancient ')" ]; then
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
options=("Geth Prune History" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Geth Prune History")            
            echo "Installing $opt"
            perform_geth_prune_history
            ;;
        "Quit")
            echo "Good bye!"
            break
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done

source ~/.bashrc
