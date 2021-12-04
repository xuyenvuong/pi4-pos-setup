#!/bin/bash
# auto_upgrade.sh - A script to quickly setup/upgrade Geth, Beacon, Validator
# Run: ./auto_upgrade.sh or setup as cronjob task
# Author: Max Vuong
# Date: 12/02/2021

# ---------------------------------------------------------------

<<COMMENT
Instructions to install and automate node upgrade for Beacon, Validator, and Geth:
 
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
COMMENT

# ---------------------------------------------------------------

beacon_metrics_url=localhost:8080/metrics
validator_metrics_url=localhost:8081/metrics
tags_url=https://api.github.com/repos/ethereum/go-ethereum/tags

process_name="auto_upgrade"

# ---------------------------------------------------------------

# Check and install jq
dpkg_name=jq

if [ $(dpkg-query -W -f='${Status}' $dpkg_name 2>/dev/null | grep -c "ok installed") -eq 0 ]
  then
    logger "Installing: $dpkg_name"
    sudo apt install -y $dpkg_name
fi

# ---------------------------------------------------------------

# Get current beacon version
beacon_curr_version=$(wget -O - -o /dev/null $beacon_metrics_url | grep buildDate= | cut -d "," -f 3 | cut -d "\"" -f 2)
logger "$process_name Beacon current version $beacon_curr_version"

# Get current validator version
validator_curr_version=$(wget -O - -o /dev/null $validator_metrics_url | grep buildDate= | cut -d "," -f 3 | cut -d "\"" -f 2)
logger "$process_name Validator current version $validator_curr_version"

# Get current geth version
geth_curr_version=$(/usr/local/bin/geth version 2> /dev/null | grep "stable" | cut -d " " -f 2 | cut -d "-" -f 1)
logger "$process_name Geth current version $geth_curr_version"

# ---------------------------------------------------------------

# Get latest available beacon version
beacon_latest_version=$($HOME/prysm/prysm.sh beacon-chain --version 2> /dev/null | grep "beacon-chain version Prysm" |  cut -d "/" -f 2)
logger "$process_name Latest beacon version $beacon_latest_version"

# Get latest available validator version
validator_latest_version=$($HOME/prysm/prysm.sh validator --version 2> /dev/null | grep "validator version Prysm" |  cut -d "/" -f 2)
logger "$process_name Latest validator version $beacon_latest_version"

# Get latest available geth version
geth_latest_version=$(wget -O - -o /dev/null $tags_url | jq '.[0].name' | cut -d "\"" -f 2 | cut -c 2-)
logger "$process_name Latest validator version $geth_latest_version"

# ---------------------------------------------------------------

# Check for beacon service
beacon_is_running=$(systemctl list-units --type=service --state=active | grep prysm-beacon | grep running)

# Check for validator service
validator_is_running=$(systemctl list-units --type=service --state=active | grep prysm-validator | grep running)

# Check for geth service
geth_is_running=$(systemctl list-units --type=service --state=active | grep geth | grep running)

# ---------------------------------------------------------------

# Deciding to upgrade beacon
if [[ $beacon_is_running && $beacon_curr_version != $beacon_latest_version ]]
  then
    logger "$process_name OK to upgrade Beacon to version "$beacon_latest_version
    sudo systemctl restart prysm-beacon.service
else
    logger "$process_name Beacon is up to date or not active."
fi

# ---------------------------------------------------------------

# Deciding to upgrade validator
if [[ $validator_is_running && $validator_curr_version != $validator_latest_version ]]
  then
    logger "$process_name OK to upgrade Validator to version "$validator_latest_version
    sudo systemctl restart prysm-validator.service
else
    logger "$process_name Validator is up to date or not active."
fi

# ---------------------------------------------------------------

# Deciding to upgrade geth 
if [[ $geth_is_running && $geth_curr_version != $geth_latest_version ]]
  then
    arch=$(dpkg --print-architecture)
    sha=$(wget -O - -o /dev/null $tags_url | jq '.[0].commit.sha' | cut -c 2-9)
    download_version=$arch-$geth_latest_version-$sha

    # Compose download URL
    download_url=https://gethstore.blob.core.windows.net/builds/geth-linux-$download_version.tar.gz
	
    # Download latest tar ball
    wget -P /tmp $download_url

    # Untar
    tar -C /tmp -xvf /tmp/geth-linux-$download_version.tar.gz
	
    # Stop geth
    sudo systemctl stop geth.service

    # Move old geth file
    sudo mv /usr/local/bin/geth /usr/local/bin/geth.$(date "+%Y%m%d-%H%M%S")
    sudo cp /tmp/geth-linux-$download_version/geth /usr/local/bin

    # Start geth
    sudo systemctl start geth.service
	
    # Clean up
    rm -rf /tmp/geth-linux-$download_version
else
    logger "$process_name Geth is up to date or not active."
fi

# ---------------------------------------------------------------
# EOF