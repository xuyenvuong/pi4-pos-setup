#!/bin/bash
# auto_upgrade.sh - A script to quickly setup/upgrade Geth, Beacon, Validator, Clientstats
# Run: ./auto_upgrade.sh or setup as cronjob task
# Author: Max Vuong
# Date: 12/02/2021

# ---------------------------------------------------------------
# README
# ---------------------------------------------------------------

: <<'COMMENT_BLOCK'
Instructions to install and automate node upgrade for Beacon, Validator, Clientstats, and Geth:
 
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

Optional Step: Add Discord Notification Webhook 
To get Discord notification webhook when there's an upgrade, please create the webhook and config DISCORD_WEBHOOK_URL with your own webhook
To remove Discord Notification, set DISCORD_WEBHOOK_URL=''

Step: Geth Prune
The script will auto do the geth prune when the disk space at 95% by default. 
Or to prune at a lower pecentage e.g. 80%, you can change GETH_PRUNE_AT_PERCENTAGE=80.
And to stop the prune, you can change GETH_PRUNE_AT_PERCENTAGE=100.
If disk is still over the defined GETH_PRUNE_AT_PERCENTAGE after prunning, prune job will be disabled for 7 days until you fix the capacity issue.


Do the same for every single node in your cluster. That's all.

COMMENT_BLOCK

# ---------------------------------------------------------------
# END README
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# Discord Notification Webhook Config
# ---------------------------------------------------------------


DISCORD_WEBHOOK_URL=''


# ---------------------------------------------------------------
# Remaining disk percentage to prune Geth database. Default to 95%
# ---------------------------------------------------------------


GETH_PRUNE_AT_PERCENTAGE=90


# ---------------------------------------------------------------
# Other configs
# ---------------------------------------------------------------


BEACON_METRICS_URL=localhost:8080/metrics
VALIDATOR_METRICS_URL=localhost:8081/metrics
PRYSM_SH_URL=https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh
TAGS_URL=https://api.github.com/repos/ethereum/go-ethereum/tags

GETH_LAST_PRUNE_FILE=/tmp/geth_last_prune

PROCESS_NAME="auto_upgrade"


# ---------------------------------------------------------------
# To send a simple notification to Discord via webhook. This function only send when DISCORD_WEBHOOK_URL variable is not null
# discord_notify $username $msg_content

function discord_notify() {
  local username=$1
  local msg_content=$2  
    
  if [ -n "$DISCORD_WEBHOOK_URL" ]; then
    curl -H "Content-Type: application/json" -X POST -d "{\"username\": \"$username\",\"content\": \"$msg_content\"}" $DISCORD_WEBHOOK_URL
  fi  
}

# ---------------------------------------------------------------

# Check and install jq
dpkg_name=jq

if [ $(dpkg-query -W -f='${Status}' $dpkg_name 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  logger "Installing: $dpkg_name"
  sudo apt install -y $dpkg_name
fi

# ---------------------------------------------------------------

# Get current beacon version
beacon_curr_version=$(wget -O - -o /dev/null $BEACON_METRICS_URL | grep buildDate= | cut -d "," -f 3 | cut -d "\"" -f 2)
logger "$PROCESS_NAME Beacon current version $beacon_curr_version"

# Get current validator version
validator_curr_version=$(wget -O - -o /dev/null $VALIDATOR_METRICS_URL | grep buildDate= | cut -d "," -f 3 | cut -d "\"" -f 2)
logger "$PROCESS_NAME Validator current version $validator_curr_version"

# Get current geth version
geth_curr_version=$(/usr/local/bin/geth version 2> /dev/null | grep "stable" | cut -d " " -f 2 | cut -d "-" -f 1)
logger "$PROCESS_NAME Geth current version $geth_curr_version"

# Geth current prysm.sh version
prysm_sh_crr_version=$(md5sum $HOME/prysm/prysm.sh | cut -d " " -f 1)
logger "$PROCESS_NAME Prysm.sh current version $prysm_sh_crr_version"

# ---------------------------------------------------------------

# Get latest available beacon version
beacon_latest_version=$($HOME/prysm/prysm.sh beacon-chain --version 2> /dev/null | grep "beacon-chain version Prysm" |  cut -d "/" -f 2)
logger "$PROCESS_NAME Latest beacon version $beacon_latest_version"

# Get latest available validator version
validator_latest_version=$($HOME/prysm/prysm.sh validator --version 2> /dev/null | grep "validator version Prysm" |  cut -d "/" -f 2)
logger "$PROCESS_NAME Latest validator version $beacon_latest_version"

# Get latest available geth version
geth_latest_version=$(wget -O - -o /dev/null $TAGS_URL | jq '.[0].name' | tr -d \" | cut -c 2-)
logger "$PROCESS_NAME Latest geth version $geth_latest_version"

# Get latest available prysm.sh version
prysm_sh_latest_version=$(wget -O - -o /dev/null $PRYSM_SH_URL | md5sum | cut -d " " -f 1)
logger "$PROCESS_NAME Latest prysm.sh current version $prysm_sh_latest_version"

# ---------------------------------------------------------------

# Check for beacon service
beacon_is_running=$(systemctl list-units --type=service --state=active | grep prysm-beacon | grep running)

# Check for validator service
validator_is_running=$(systemctl list-units --type=service --state=active | grep prysm-validator | grep running)

# Check for clientstats service
clientstats_is_running=$(systemctl list-units --type=service --state=active | grep prysm-clientstats | grep running)

# Check for geth service
geth_is_running=$(systemctl list-units --type=service --state=active | grep geth | grep running)

# ---------------------------------------------------------------

# Deciding to upgrade prysm.sh
if [[ -e $HOME/prysm/prysm.sh && $prysm_sh_crr_version != $prysm_sh_latest_version ]]; then 
  # Move old prysm.sh file
  prysm_sh_backup_filename=$HOME/prysm/prysm.sh.$(date "+%Y%m%d-%H%M%S")
  
  sudo mv $HOME/prysm/prysm.sh $prysm_sh_backup_filename
  
  # Download latest prysm.sh
  curl https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh --output $HOME/prysm/prysm.sh
  chmod +x $HOME/prysm/prysm.sh
      
  if [ -e $HOME/prysm/prysm.sh ]; then
    logger "$PROCESS_NAME Upgraded prysm.sh to latest md5sum $prysm_sh_latest_version"
    
    # Notify Discord
    discord_notify $PROCESS_NAME "Upgraded prysm.sh to latest md5sum $prysm_sh_latest_version"
  else
    # Roll back
    sudo mv $prysm_sh_backup_filename $HOME/prysm/prysm.sh 
  fi
fi

# Deciding to upgrade beacon
if [[ $beacon_is_running && $beacon_curr_version != $beacon_latest_version ]]; then
  logger "$PROCESS_NAME OK to upgrade Beacon to version $beacon_latest_version"
  sudo systemctl restart prysm-beacon.service

  discord_notify $PROCESS_NAME "Upgraded Beacon to version $beacon_latest_version"
else
  logger "$PROCESS_NAME Beacon is up to date or not active."
fi

# ---------------------------------------------------------------

# Deciding to upgrade validator
if [[ $validator_is_running && $validator_curr_version != $validator_latest_version ]]; then
  logger "$PROCESS_NAME OK to upgrade Validator to version $validator_latest_version"
  sudo systemctl restart prysm-validator.service

  discord_notify $PROCESS_NAME "Upgraded Validator to version $validator_latest_version"
else
  logger "$PROCESS_NAME Validator is up to date or not active."
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
  
  arch=$(dpkg --print-architecture)
  sha=$(wget -O - -o /dev/null $TAGS_URL | jq '.[0].commit.sha' | cut -c 2-9)
  download_version=$arch-$geth_latest_version-$sha

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
      discord_notify $PROCESS_NAME "Upgraded Geth to version $geth_latest_version"      
    else
      # Roll back binary file
      logger "$PROCESS_NAME Failed to copy latest geth binary to /usr/local/bin. Performing rollback now."
      
      # Notify Discord
      discord_notify $PROCESS_NAME "Failed to copy latest geth binary to /usr/local/bin. Performing rollback now."
      
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

# Geth data directory
geth_datadir=$(cat /etc/ethereum/geth.conf 2> /dev/null | awk -F'--datadir ' '{print $2}' | cut -d ' ' -f 1)

# Current disk usage
disk_used_percentage=$(df $geth_datadir | awk 'END{print $5}' | cut -d '%' -f 1)
logger "$PROCESS_NAME Geth disk usage reaches $disk_used_percentage%"

# Check last prune timestamp
if [ ! -e $GETH_LAST_PRUNE_FILE ]; then
  date +"%s" > $GETH_LAST_PRUNE_FILE
fi

geth_is_prune_time=false
geth_last_prune_timestamp=$(<$GETH_LAST_PRUNE_FILE)
current_timestamp=$(date +"%s")

# Prune if last prune was older than 1 week
if [ $((geth_last_prune_timestamp + 60*60*24*7 - current_timestamp)) -le 0 ]; then
  geth_is_prune_time=true
fi

# ---------------------------------------------------------------

# Deciding to prune geth
if [[ $geth_is_running && $geth_is_prune_time = true && $disk_used_percentage -ge $GETH_PRUNE_AT_PERCENTAGE ]]; then
  # Stop geth
  sudo systemctl stop geth.service

  # Notify Discord
  discord_notify $PROCESS_NAME "Geth prune-state starting. Don't turn off your server."

  # Run geth prune
  /usr/local/bin/geth snapshot prune-state --datadir $geth_datadir

  # Start geth
  sudo systemctl start geth.service

  # Mark prune timestamp
  echo $current_timestamp > $GETH_LAST_PRUNE_FILE

  # Notify Discord
  discord_notify $PROCESS_NAME "Geth prune-state is completed."

  # Check disk usage after prune
  disk_used_percentage=$(df -lh 2> /dev/null | grep $(du -hs $geth_datadir 2> /dev/null | awk '{print $1}') | awk '{print $5}' | cut -d '%' -f 1)
  
  if [ $disk_used_percentage -ge $GETH_PRUNE_AT_PERCENTAGE ]; then
    # Remove file to stop prunning again until disk capacity is under the threshold
    rm $GETH_LAST_PRUNE_FILE

    logger "$PROCESS_NAME WARNING: Geth disk usage reaches full capacity."	  

    # Notify Discord
    discord_notify $PROCESS_NAME "WARNING: Geth disk usage reaches full capacity. Prunning job will be deactivated for 7 days. Please fix it asap."
  fi
fi

# ---------------------------------------------------------------

# EOF
