#!/bin/bash
# auto_upgrade.sh - A script to quickly setup/upgrade Geth, Beacon, Validator, Clientstats
# Run: ./auto_upgrade.sh or setup as cronjob task
# Author: Max Vuong
# Date: 12/02/2021

# ---------------------------------------------------------------
# README
# ---------------------------------------------------------------

: <<'COMMENT_BLOCK'
Instructions to install and automate node upgrade for Beacon, Validator, Clientstats, Mevboost, and Geth:
 
Step 1: One time download from repo:
Run:
> wget https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/auto_upgrade.sh && chmod +x auto_upgrade.sh

Step 2: Enable Cronjob:
Run this command to edit crontab
> EDITOR=vim crontab -e

Add this to the bottom of the file to run your upgrade at 1:30 AM daily
> 30 1 * * * $HOME/auto_upgrade.sh
or if you prefer to run at 2:45 PM daily, then use this
> 45 14 * * * $HOME/auto_upgrade.sh

Then, save file.

Step 3: Allow Sudoer:
In order for the cronjob task to restart the processes, you need to add your current user to the "sudoer" list, this is one time step, here is how:
Run:
> sudo EDITOR=vim visudo

Add this line at the bottom. 
> ubuntu ALL=(ALL) NOPASSWD:ALL
NOTICE: if your user is not `ubuntu`, then you must change the user to the one you are login with. E.g. If your user login is `billgates`, then you must edit it to:
> billgates ALL=(ALL) NOPASSWD:ALL

Then, save file.

Do the same for every single node in your cluster. That's all.

COMMENT_BLOCK

# ---------------------------------------------------------------
# END README
# ---------------------------------------------------------------

echo "Auto Upgrade is in progress..."

# ---------------------------------------------------------------
# Other configs
# ---------------------------------------------------------------

PROCESS_NAME="Auto Upgrade:"

BEACON_METRICS_URL=localhost:8080/metrics
VALIDATOR_METRICS_URL=localhost:8081/metrics

PRYSM_RELEASES_LATEST=https://api.github.com/repos/prysmaticlabs/prysm/releases/latest
PRYSM_SH_URL=https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh

GETH_TAGS_URL=https://api.github.com/repos/ethereum/go-ethereum/tags
GETH_RELEASES_LATEST=https://api.github.com/repos/ethereum/go-ethereum/releases/latest
GETH_LAST_PRUNE_FILE=/tmp/geth_last_prune

MEVBOOST_RELEASES_LATEST=https://api.github.com/repos/flashbots/mev-boost/releases/latest

ARCH=$(dpkg --print-architecture)

# ---------------------------------------------------------------
# To send a simple notification to Discord via webhook. This function only send when DISCORD_WEBHOOK_URL variable is not null
# discord_notify $msg_content

function discord_notify() {
  if [ -e /srv/discord_notify.sh ]; then
    /srv/discord_notify.sh "$*"
  fi
}

# ---------------------------------------------------------------
# Check and install package

function install_package() {
  local dpkg_name=$1

  if [ $(dpkg-query -W -f='${Status}' $dpkg_name 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    logger "Installing: $dpkg_name"
    sudo apt install -y $dpkg_name
  fi
}

# ---------------------------------------------------------------

# Install jq
install_package jq

# Check for beacon service
beacon_is_running=$(systemctl list-units --type=service --state=active | grep prysm-beacon | grep running)

# Check for validator service
validator_is_running=$(systemctl list-units --type=service --state=active | grep prysm-validator | grep running)

# Check for mevboost service
mevboost_is_running=$(systemctl list-units --type=service --state=active | grep mevboost | grep running)

# Check for clientstats service
clientstats_is_running=$(systemctl list-units --type=service --state=active | grep prysm-clientstats | grep running)

# Check for geth service
geth_is_running=$(systemctl list-units --type=service --state=active | grep geth | grep running)

# ---------------------------------------------------------------

# Get latest available beacon version
beacon_latest_version=""
if [[ $beacon_is_running ]]; then
  beacon_latest_version=$(wget -O - -o /dev/null $PRYSM_RELEASES_LATEST | jq '.tag_name' | tr -d \")
  logger "$PROCESS_NAME Latest beacon version $beacon_latest_version"
fi

# Get latest available validator version
validator_latest_version=""
if [[ $validator_is_running ]]; then
  validator_latest_version=$(wget -O - -o /dev/null $PRYSM_RELEASES_LATEST | jq '.tag_name' | tr -d \")
  logger "$PROCESS_NAME Latest validator version $beacon_latest_version"
fi

# Get latest available MEV-Boost version
mevboost_latest_version=""
if [[ $mevboost_is_running ]]; then
  mevboost_latest_version=$(wget -O - -o /dev/null $MEVBOOST_RELEASES_LATEST | jq '.tag_name' | tr -d \")
  logger "$PROCESS_NAME Latest MEV-Boost version $mevboost_latest_version"
fi

# Get latest available geth version
geth_latest_version=""
if [[ $geth_is_running ]]; then
  geth_latest_version=$(wget -O - -o /dev/null $GETH_RELEASES_LATEST | jq '.tag_name' | tr -d \" | cut -c 2-)
  logger "$PROCESS_NAME Latest geth version $geth_latest_version"
fi

# Get latest available prysm.sh version
prysm_sh_latest_version=$(wget -O - -o /dev/null $PRYSM_SH_URL | md5sum | cut -d " " -f 1)
logger "$PROCESS_NAME Latest prysm.sh current version $prysm_sh_latest_version"

# ---------------------------------------------------------------

# Get current beacon version
beacon_curr_version=""
if [[ $beacon_is_running ]]; then
  beacon_curr_version=$(wget -O - -o /dev/null $BEACON_METRICS_URL | grep buildDate= | cut -d "," -f 3 | cut -d "\"" -f 2)
  logger "$PROCESS_NAME Beacon current version $beacon_curr_version"
fi

# Get current validator version
validator_curr_version=""
if [[ $validator_is_running ]]; then
  validator_curr_version=$(wget -O - -o /dev/null $VALIDATOR_METRICS_URL | grep buildDate= | cut -d "," -f 3 | cut -d "\"" -f 2)
  logger "$PROCESS_NAME Validator current version $validator_curr_version"
fi

# MEV-Boost current version
mevboost_curr_version=""
if [[ $mevboost_is_running ]]; then
  mevboost_curr_version=$(/usr/local/bin/mev-boost -version | awk '{print $2}')
  logger "$PROCESS_NAME MEV-Boost current version $mevboost_curr_version"
fi

# Get current geth version
geth_curr_version=""
if [[ $geth_is_running ]]; then
  geth_curr_version=$(/usr/local/bin/geth version 2> /dev/null | grep "stable" | cut -d " " -f 2 | cut -d "-" -f 1)
  logger "$PROCESS_NAME Geth current version $geth_curr_version"
fi

# Geth current prysm.sh version
prysm_sh_curr_version=""
if [ -e $HOME/prysm/prysm.sh ]; then
  prysm_sh_curr_version=$(md5sum $HOME/prysm/prysm.sh | cut -d " " -f 1)
  logger "$PROCESS_NAME Prysm.sh current version $prysm_sh_curr_version"
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
    logger "$PROCESS_NAME Upgraded prysm.sh to latest md5sum $prysm_sh_latest_version"
    
    # Notify Discord
    discord_notify "$PROCESS_NAME Upgraded prysm.sh to latest md5sum $prysm_sh_latest_version"
  else
    # Roll back
    sudo mv $prysm_sh_backup_filename $HOME/prysm/prysm.sh 
  fi
fi

# Deciding to upgrade beacon
if [[ $beacon_is_running && $beacon_curr_version != $beacon_latest_version ]]; then
  logger "$PROCESS_NAME OK to upgrade Beacon to version $beacon_latest_version"
  sudo systemctl restart prysm-beacon.service

  discord_notify "$PROCESS_NAME Upgraded Beacon to version $beacon_latest_version"
else
  logger "$PROCESS_NAME Beacon is up to date or not active."
fi

# ---------------------------------------------------------------

# Deciding to upgrade validator
if [[ $validator_is_running && $validator_curr_version != $validator_latest_version ]]; then
  logger "$PROCESS_NAME OK to upgrade Validator to version $validator_latest_version"
  sudo systemctl restart prysm-validator.service

  discord_notify "$PROCESS_NAME Upgraded Validator to version $validator_latest_version"
else
  logger "$PROCESS_NAME Validator is up to date or not active."
fi

# ---------------------------------------------------------------

# Deciding to upgrade MEV-Boost
if [[ $mevboost_is_running && $mevboost_curr_version != $mevboost_latest_version ]]; then
  logger "$PROCESS_NAME OK to upgrade MEV-Boost to version $mevboost_latest_version"

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
else
  logger "$PROCESS_NAME MEV-Boost is up to date or not active."
fi

# ---------------------------------------------------------------

# Deciding to restart clientstats
if [[ $beacon_curr_version != $beacon_latest_version || $validator_curr_version != $validator_latest_version ]]; then
  if [[ $clientstats_is_running ]]; then
    sudo systemctl restart prysm-clientstats.service
  fi
fi

# ---------------------------------------------------------------

# Deciding to upgrade geth 
if [[ $geth_is_running && $geth_curr_version != $geth_latest_version ]]; then
  logger "$PROCESS_NAME OK to upgrade GETH to version $geth_latest_version"
   
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
      logger "$PROCESS_NAME Copied geth binary to /usr/local/bin"
      logger "$PROCESS_NAME Upgraded Geth to version $geth_latest_version"
      
      # Notify Discord
      discord_notify "$PROCESS_NAME Upgraded Geth to version $geth_latest_version"      
    else
      # Roll back binary file
      logger "$PROCESS_NAME Failed to copy latest geth binary to /usr/local/bin. Performing rollback now."
      
      # Notify Discord
      discord_notify "$PROCESS_NAME Failed to copy latest geth binary to /usr/local/bin. Performing rollback now."
      
      sudo mv $geth_backup_filename /usr/local/bin/geth          
    fi

    # Start geth
    sudo systemctl start geth.service
  
    # Clean up
    rm -rf /tmp/geth-linux-$download_version*
  else
    logger "$PROCESS_NAME Geth file was not downloaded /tmp/geth-linux-$download_version/geth. Try again tomorrow."
  fi
else
  logger "$PROCESS_NAME Geth is up to date or not active."
fi

# ---------------------------------------------------------------

echo "Auto Upgrade is done."
# EOF