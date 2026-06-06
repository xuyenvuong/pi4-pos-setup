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

# Set Beacon data path
function set_beacon_data_path() {
  if [ -e ~/prysm/configs/beacon.yaml ]; then
    read -p "Enter beacon data path (e.g. /mnt/ssdxxxx/beacon): " beacon_data_path
    
    sudo sed -i "s|^datadir.*$|datadir: \"$beacon_data_path\"|" ~/prysm/configs/beacon.yaml
  else
    echo "Error. Please setup Beacon first."
  fi
}

# Set Geth data path
function set_geth_data_path() {
  if [ -e /etc/ethereum/geth.conf ]; then
    read -p "Enter geth data path (e.g. /mnt/ssdxxxx/chaindata): " geth_data_path
    
    sudo sed -i "s|^\s--datadir\s.*$| --datadir $geth_data_path|" /etc/ethereum/geth.conf
  else
    echo "Error. Please setup Geth first."
  fi
}

# Set Geth ancient data path
function set_geth_ancient_data_path() {
  if [ -e /etc/ethereum/geth.conf ]; then
    read -p "Enter geth ancient data path (e.g. /mnt/ssdxxxx/ancientdb): " geth_ancient_data_path
    
    sudo sed -i "s|^\s--datadir\.ancient.*$| --datadir.ancient $geth_ancient_data_path|" /etc/ethereum/geth.conf
  else
    echo "Error. Please setup Geth first."
  fi
}

# Set Wallet
function set_wallet() {
  if [ -e ~/prysm/configs/beacon.yaml ]; then
    read -p "Enter walled address: " wallet_address
    
    sudo sed -i "s|^suggested-fee-recipient.*$|suggested-fee-recipient: $wallet_address|" ~/prysm/configs/beacon.yaml
  else
    echo "Error. Please setup Beacon first."
  fi
}

# Set Wallet
function set_host_dns() {
  if [ -e ~/prysm/configs/beacon.yaml ]; then
    read -p "Enter host DNS: " host_dns
    
    sudo sed -i "s|^p2p-host-dns.*$|p2p-host-dns: \"$host_dns\"|" ~/prysm/configs/beacon.yaml
  else
    echo "Error. Please setup Beacon first."
  fi

}

# Set Discord URL
function set_discord_url() {  
  if [ -e /srv/discord_notify.sh ]; then
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
options=("Geth Prune History" "Set Beacon Data Path" "Set Geth Data Path" "Set Geth Ancient Data Path" "Set Wallet" "Set Host DNS" "Set Discord URL" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Geth Prune History")
            echo "Start $opt"
            perform_geth_prune_history
            ;;
        "Set Beacon Data Path")
            set_beacon_data_path
            ;;
        "Set Geth Data Path")
            set_geth_data_path
            ;;
        "Set Geth Ancient Data Path")
            set_geth_ancient_data_path
            ;;
        "Set Wallet")
            set_wallet
            ;;
        "Set Host DNS")
            set_host_dns
            ;;
        "Set Discord URL")
            Set_discord_url
            ;;        
        "Quit")
            echo "Good bye!"
            break
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done

source ~/.bashrc
