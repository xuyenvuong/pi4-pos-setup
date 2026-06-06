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
  data_dir_ancient=$(cat /etc/ethereum/geth.conf | grep 'datadir.ancient ')

  if [ -e /usr/local/bin/geth ]; then
    sudo systemctl stop prysm-beacon.service
    sudo systemctl stop geth.service

    if [ -z "$data_dir_ancient" ]; then
      /usr/local/bin/geth prune-history --history.chain postmerge $data_dir
    else
      /usr/local/bin/geth prune-history --history.chain postmerge $data_dir $data_dir_ancient
    fi

    sudo systemctl start prysm-beacon.service
    sudo systemctl start geth.service

    echo "Done: Prunning history is completed."
  fi
}

# Config Discord URL
function config_discord_url() {  
  if [ ! -e /srv/discord_notify.sh ]; then
    read -p "Enter full Discord URL: " discord_url
    
    sudo sed -i "s|^DISCORD_WEBHOOK_URL.*$|DISCORD_WEBHOOK_URL=\'$discord_url\'|" /srv/discord_notify.sh
    
  else
    echo "Error. Please setup discord_notify.sh first."
  fi
}

#-------------------------------------------------------------------------------------------#
# Utils prompt
#-------------------------------------------------------------------------------------------#

PS3='Please enter your command choice: '
options=("Geth Prune History" "Config Discord URL" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Geth Prune History")
            echo "Start $opt"
            perform_geth_prune_history
            ;;
        "Config Discord URL")
            config_discord_url
            ;;
        "Quit")
            echo "Good bye!"
            break
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done

source ~/.bashrc
