#!/bin/bash
# helper.sh - A script to quickly setup/upgrade Geth
# Author: Max Vuong
# Date: 10/17/2021

tags=https://api.github.com/repos/ethereum/go-ethereum/tags
tags_file=/tmp/tags

# ---------------------------------------------------------------

# Download tags JSON
echo "Get latest version info..."
wget -P /tmp $tags

arch=$(dpkg --print-architecture)
sha=$(jq '.[0].commit.sha' /tmp/tags | cut -c 2-9)
latest_version=$(jq '.[0].name' /tmp/tags | cut -d "\"" -f 2 | cut -c 2-30)

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
rm /tmp/tags*

# EOF