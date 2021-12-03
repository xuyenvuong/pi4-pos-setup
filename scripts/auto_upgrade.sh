#!/bin/bash
# auto_upgrade.sh - A script to quickly setup/upgrade Geth, Beacon, Validator
# Run: ./auto_upgrade.sh
# Author: Max Vuong
# Date: 12/02/2021

# ---------------------------------------------------------------

beacon_metric_url=localhost:8080/metrics
validator_metric_url=localhost:8081/metrics
tags_url=https://api.github.com/repos/ethereum/go-ethereum/tags

# ---------------------------------------------------------------

# Check and install jq
dpkg_name=jq

if [ $(dpkg-query -W -f='${Status}' $dpkg_name 2>/dev/null | grep -c "ok installed") -eq 0 ]
  then
    echo "Installing: $dpkg_name"
    sudo apt install -y $dpkg_name
fi

# ---------------------------------------------------------------

# Get current beacon version
beacon_curr_version=$(wget -O - -o /dev/null $beacon_metric_url | grep buildDate= | cut -d "," -f 3 | cut -d "\"" -f 2)
echo "Beacon current version $beacon_curr_version"

# Get current validator version
validator_curr_version=$(wget -O - -o /dev/null $validator_metric_url | grep buildDate= | cut -d "," -f 3 | cut -d "\"" -f 2)
echo "Validator current version $validator_curr_version"

# Get current geth version
geth_curr_version=$(/usr/local/bin/geth version 2> /dev/null | grep "stable" | cut -d " " -f 2 | cut -d "-" -f 1)
echo "Geth current version $geth_curr_version"

# ---------------------------------------------------------------

# Get latest available beacon version
beacon_latest_version=$($HOME/prysm/prysm.sh beacon-chain --version 2> /dev/null | grep "beacon-chain version Prysm" |  cut -d "/" -f 2)
echo "Latest beacon version $beacon_latest_version"

# Get latest available validator version
validator_latest_version=$($HOME/prysm/prysm.sh validator --version 2> /dev/null | grep "validator version Prysm" |  cut -d "/" -f 2)
echo "Latest validator version $beacon_latest_version"

# Get latest available geth version
geth_latest_version=$(wget -O - -o /dev/null $tags_url | jq '.[0].name' | cut -d "\"" -f 2 | cut -c 2-)
echo "Latest validator version $geth_latest_version"

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
    echo "OK to upgrade Beacon to version "$beacon_latest_version
	sudo systemctl restart prysm-beacon.service
else
    echo "Beacon is up to date or not active."
fi

# ---------------------------------------------------------------

# Deciding to upgrade validator
if [[ $validator_is_running && $validator_curr_version != $validator_latest_version ]]
  then
    echo "OK to upgrade Validator to version "$validator_latest_version
	sudo systemctl restart prysm-validator.service
else
    echo "Validator is up to date or not active."
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
fi

# ---------------------------------------------------------------
# EOF