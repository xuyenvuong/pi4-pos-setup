#!/bin/bash
# upgrde_go_lib.sh - A script to upgrade GO Lib to the latest version
# Author: Max Vuong
# Date: 02/28/2024

: <<'COMMENT_BLOCK'
Run this command to upgrade GO library to the latest version.
> curl -L https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/upgrade_go_lib.sh | bash && source ~/.bashrc

COMMENT_BLOCK

# ---------------------------------------------------------------
cd ~

GO_LATEST_VERSION_JSON=https://go.dev/dl/?mode=json
GO_BIN_DOWNLOAD_URL=https://go.dev/dl/

ARCH=$(dpkg --print-architecture)

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

go_latest_version=$(wget -O - -o /dev/null $GO_LATEST_VERSION_JSON | jq '.[0].files | .[] | select(.os=="linux" and .arch=="'$ARCH'") | .filename'  | tr -d \")

echo "Version: $go_latest_version"

go_bin_tar_url="$GO_BIN_DOWNLOAD_URL$go_latest_version"
echo "Download URL: go_bin_tar_url"

echo "Start downloading..."

wget -P /tmp $go_bin_tar_url

echo "Downloaded successfully."

echo "Remove legacy version at /usr/local/go"
sudo rm -rvf /usr/local/go

echo "Untar to /usr/local"
sudo tar -xvf /tmp/$go_latest_version -C /usr/local

echo "Clean up..."
rm -rf /tmp/$go_latest_version

echo "Update .bashrc GOROOT and GOPATH variables"

sudo sed -i "/GoLang/d" ~/.bashrc
sudo sed -i "/GOROOT/d" ~/.bashrc
sudo sed -i "/GOPATH/d" ~/.bashrc
# Replace multiples blank lines with one blank line
sudo sed -i "$!N;/^\n$/{$q;D;};P;D;" ~/.bashrc

sudo cat << EOF | sudo tee -a $HOME/.bashrc >/dev/null
# GoLang
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH
EOF

source ~/.bashrc

echo "Verify installed version: "
go version

echo "Done"