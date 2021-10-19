#!/bin/bash
# geth_upgrade.sh - A script to quickly setup/upgrade Geth
# Run: ./geth_upgrade.sh
# Author: Max Vuong
# Date: 10/17/2021

# ---------------------------------------------------------------

tags=https://api.github.com/repos/ethereum/go-ethereum/tags
tags_file=/tmp/tags

# ---------------------------------------------------------------

# Check and install jq
dpkg_name=jq

if [ $(dpkg-query -W -f='${Status}' $dpkg_name 2>/dev/null | grep -c "ok installed") -eq 0 ]
  then
    echo "Installing: $dpkg_name"
    sudo apt install -y $dpkg_name
fi

# ---------------------------------------------------------------

# Download tags JSON
echo "Get latest version info..."
wget -P /tmp $tags

arch=$(dpkg --print-architecture)
sha=$(jq '.[0].commit.sha' < $tags_file | cut -c 2-9)
latest_version=$(jq '.[0].name' < $tags_file | cut -d "\"" -f 2 | cut -c 2-30)

# Compose download URL
download_url=https://gethstore.blob.core.windows.net/builds/geth-linux-$arch-$latest_version-$sha.tar.gz

# Download latest tar ball
wget -P /tmp $download_url

# Untar
tar -C /tmp -xvf /tmp/geth-linux-$arch-$latest_version-$sha.tar.gz

# Stop geth
sudo systemctl stop geth.service

# Move old geth file
sudo mv /usr/local/bin/geth /usr/local/bin/geth.$(date "+%Y%m%d-%H%M%S")
sudo cp /tmp/geth-linux-$arch-$latest_version-$sha/geth /usr/local/bin

# Start geth
sudo systemctl start geth.service

echo "Success: Geth has upgraded to version v$latest_version). Please run the below command to make sure there is no error in the log:"
echo "journalctl -f -u geth.service -n 200"

# ---------------------------------------------------------------
# Clean up
rm -rf /tmp/geth-linux-$arch-$latest_version-$sha
rm $tags_file*

# EOF