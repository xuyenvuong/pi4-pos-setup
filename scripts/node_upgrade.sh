#!/bin/bash
# node_upgrade.sh - A script to quickly setup/upgrade Geth, Beacon, Validator, Clientstats
# Run: ./auto_upgrade.sh or setup as cronjob task
# Author: Max Vuong
# Date: 06/05/2026

# ---------------------------------------------------------------
# README
# ---------------------------------------------------------------

: <<'COMMENT_BLOCK'
Instructions to install and automate node upgrade for Beacon, Validator, Clientstats, Mevboost, and Geth:

Run:
> bash <(curl -s https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/node_upgrade.sh)

COMMENT_BLOCK

# ---------------------------------------------------------------
# END README
# ---------------------------------------------------------------

echo "Node upgrade is in progress..."

# ---------------------------------------------------------------

source <(curl -s https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/refs/heads/master/scripts/lib.sh)

# ---------------------------------------------------------------

# ---------------------------------------------------------------
# Other configs
# ---------------------------------------------------------------

PROCESS_NAME="Auto Upgrade:"

PRYSM_VERSION_URL=http://localhost:3500/eth/v1/node/version

PRYSM_RELEASES_LATEST=https://api.github.com/repos/prysmaticlabs/prysm/releases/latest
PRYSM_SH_URL=https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh

GETH_TAGS_URL=https://api.github.com/repos/ethereum/go-ethereum/tags
GETH_RELEASES_LATEST=https://api.github.com/repos/ethereum/go-ethereum/releases/latest

MEVBOOST_RELEASES_LATEST=https://api.github.com/repos/flashbots/mev-boost/releases/latest

# ---------------------------------------------------------------

# Install jq
install_package jq

# Check for beacon service
declare -i beacon_is_running=$(is_service_running prysm-beacon)

# Check for validator service
declare -i validator_is_running=$(is_service_running prysm-validator)

# Check for mevboost service
declare -i mevboost_is_running=$(is_service_running mevboost)

# Check for geth service
declare -i geth_is_running=$(is_service_running geth)

# ---------------------------------------------------------------

# Get latest available beacon version
beacon_latest_version=""
if [[ $beacon_is_running -eq 1 ]]; then
  beacon_latest_version=$(wget -O - -o /dev/null $PRYSM_RELEASES_LATEST | jq '.tag_name' | tr -d \")  
fi

# Get latest available validator version
validator_latest_version=""
if [[ $validator_is_running -eq 1 ]]; then
  validator_latest_version=$(wget -O - -o /dev/null $PRYSM_RELEASES_LATEST | jq '.tag_name' | tr -d \")  
fi

# Get latest available MEV-Boost version
mevboost_latest_version=""
if [[ $mevboost_is_running -eq 1 ]]; then
  mevboost_latest_version=$(wget -O - -o /dev/null $MEVBOOST_RELEASES_LATEST | jq '.tag_name' | tr -d \")  
fi

# Get latest available geth version
geth_latest_version=""
if [[ $geth_is_running -eq 1 ]]; then
  geth_latest_version=$(wget -O - -o /dev/null $GETH_RELEASES_LATEST | jq '.tag_name' | tr -d \" | cut -c 2-)  
fi

# Get latest available prysm.sh version
prysm_sh_latest_version=$(wget -O - -o /dev/null $PRYSM_SH_URL | md5sum | cut -d " " -f 1)

# ---------------------------------------------------------------

# Get current beacon version
beacon_curr_version=""
if [[ $beacon_is_running -eq 1 ]]; then  
  beacon_curr_version=$(curl -s $PRYSM_VERSION_URL | jq '.data.version' | cut -d "-" -f 1 | cut -d "/" -f 2)
fi

# Get current validator version
validator_curr_version=""
if [[ $validator_is_running -eq 1 ]]; then
    validator_curr_version=$(curl -s $PRYSM_VERSION_URL | jq '.data.version' | cut -d "-" -f 1 | cut -d "/" -f 2)
fi

# MEV-Boost current version
mevboost_curr_version=""
if [[ $mevboost_is_running -eq 1 ]]; then
  mevboost_curr_version=$(/usr/local/bin/mev-boost -version | awk '{print $2}')  
fi

# Get current geth version
geth_curr_version=""
if [[ $geth_is_running -eq 1 ]]; then
  geth_curr_version=$(/usr/local/bin/geth version 2> /dev/null | grep "stable" | cut -d " " -f 2 | cut -d "-" -f 1)  
fi

# Geth current prysm.sh version
prysm_sh_curr_version=""
if [ -e $HOME/prysm/prysm.sh ]; then
  prysm_sh_curr_version=$(md5sum $HOME/prysm/prysm.sh | cut -d " " -f 1)
fi

# ---------------------------------------------------------------

# Deciding to upgrade prysm.sh
if [[ -e $HOME/prysm/prysm.sh && $prysm_sh_curr_version != $prysm_sh_latest_version ]]; then 
  # Move old prysm.sh file
  prysm_sh_backup_filename=$HOME/prysm/prysm.sh.$(date "+%Y%m%d-%H%M%S")
  
  sudo mv $HOME/prysm/prysm.sh $prysm_sh_backup_filename
  
  # Download latest prysm.sh
  curl $PRYSM_SH_URL --output $HOME/prysm/prysm.sh
  chmod +x $HOME/prysm/prysm.sh
      
  if [ -e $HOME/prysm/prysm.sh ]; then    
    # Notify Discord
    discord_notify "$PROCESS_NAME Upgraded prysm.sh to latest md5sum $prysm_sh_latest_version"
  else
    # Roll back
    sudo mv $prysm_sh_backup_filename $HOME/prysm/prysm.sh 
  fi
fi

# Deciding to upgrade beacon
if [[ $beacon_is_running -eq 1 && $beacon_curr_version != $beacon_latest_version ]]; then  
  sudo systemctl restart prysm-beacon.service

  discord_notify "$PROCESS_NAME Upgraded Beacon to version $beacon_latest_version"
fi

# ---------------------------------------------------------------

# Deciding to upgrade validator
if [[ $validator_is_running -eq 1 && $validator_curr_version != $validator_latest_version ]]; then  
  sudo systemctl restart prysm-validator.service

  discord_notify "$PROCESS_NAME Upgraded Validator to version $validator_latest_version"
fi

# ---------------------------------------------------------------

# Deciding to upgrade MEV-Boost
if [[ $mevboost_is_running -eq 1 && $mevboost_curr_version != $mevboost_latest_version ]]; then
  CGO_CFLAGS="-O -D__BLST_PORTABLE__" /usr/local/go/bin/go install github.com/flashbots/mev-boost@latest

  md5sum_curr_bin=$(md5sum /usr/local/bin/mev-boost | awk '{print $1}')
  md5sum_new_bin=$(md5sum go/bin/mev-boost | awk '{print $1}')

  if [[ $md5sum_curr_bin != $md5sum_new_bin ]]; then
    # Move old mevboost file
    mevboost_backup_filename=/usr/local/bin/mev-boost.$(date "+%Y%m%d-%H%M%S")
    
    sudo systemctl stop mevboost.service

    sudo mv /usr/local/bin/mev-boost $mevboost_backup_filename
    sudo cp ~/go/bin/mev-boost /usr/local/bin

    sudo systemctl start mevboost.service

    discord_notify "$PROCESS_NAME Upgraded MEV-Boost to version $mevboost_latest_version"
  fi
fi

# ---------------------------------------------------------------

# Deciding to upgrade geth 
if [[ $geth_is_running -eq 1 && $geth_curr_version != $geth_latest_version ]]; then
  sha=$(wget -O - -o /dev/null $GETH_TAGS_URL | jq '.[0].commit.sha' | cut -c 2-9)
  download_version=$ARCH-$geth_latest_version-$sha

  # Compose download URL
  download_url=https://gethstore.blob.core.windows.net/builds/geth-linux-$download_version.tar.gz

  # Download latest tar ball
  wget -P /tmp $download_url

  # Untar
  tar -C /tmp -xvf /tmp/geth-linux-$download_version.tar.gz
  
  if [ -e /tmp/geth-linux-$download_version/geth ]; then
    # Stop geth
    sudo systemctl stop geth.service

    # Move old geth file
    geth_backup_filename=/usr/local/bin/geth.$(date "+%Y%m%d-%H%M%S")
    
    sudo mv /usr/local/bin/geth $geth_backup_filename
    sudo cp /tmp/geth-linux-$download_version/geth /usr/local/bin
    
    # Check to make sure binary file is copied correctly
    if [ -e /usr/local/bin/geth ]; then
      # Notify Discord
      discord_notify "$PROCESS_NAME Upgraded Geth to version $geth_latest_version"      
    else
      # Notify Discord
      discord_notify "$PROCESS_NAME Failed to copy latest geth binary to /usr/local/bin. Performing rollback now."
      
      sudo mv $geth_backup_filename /usr/local/bin/geth          
    fi

    # Start geth
    sudo systemctl start geth.service
  
    # Clean up
    rm -rf /tmp/geth-linux-$download_version* 
  fi
fi

# ---------------------------------------------------------------

echo "Auto Upgrade is done."
# EOF