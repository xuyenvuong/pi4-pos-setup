#!/bin/bash
# upgrde_go_lib.sh - A script to upgrade GO Lib to the latest version
# Author: Max Vuong
# Date: 02/28/2024

: <<'COMMENT_BLOCK'
Run this command to update and migrate the auto_upgrade.sh script
> curl -L https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/upgrade_go_lib.sh | bash

COMMENT_BLOCK

# ---------------------------------------------------------------
cd ~


# [
#   {
#     "filename": "go1.22.0.linux-amd64.tar.gz",
#     "os": "linux",
#     "arch": "amd64",
#     "version": "go1.22.0",
#     "sha256": "f6c8a87aa03b92c4b0bf3d558e28ea03006eb29db78917daec5cfb6ec1046265",
#     "size": 68988925,
#     "kind": "archive"
#    }
# ]


GO_LATEST_VERSION_JSON=https://go.dev/dl/?mode=json


GO_BIN_TAR=https://go.dev/dl/go1.22.0.linux-amd64.tar.gz

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

# ---------------------------------------------------------------

#go_latest_version=$(wget -O - -o /dev/null $GO_LATEST_VERSION_JSON | jq '.[] | select(.color=="yellow" and .price>=0.5)' | tr -d \")
go_latest_version=$(wget -O - -o /dev/null $GO_LATEST_VERSION_JSON | jq '.[0].files | .[] | select(.os=="linux" and .arch=="amd64") | .filename'  | tr -d \")

echo "Version: $go_latest_version"

echo "Start downloading..."


