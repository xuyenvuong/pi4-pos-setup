#!/bin/bash
# lib.sh - Common useful function


: <<'COMMENT_BLOCK'
Instructions to run the lib script:

Include this line to other script:
> source <(curl -s https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/refs/heads/master/scripts/lib.sh)

COMMENT_BLOCK

#-------------------------------------------------------------------------------------------#

set -eu

# Install package
function install_package() {
  local dpkg_name=$1

  if [ $(dpkg-query -W -f='${Status}' $dpkg_name 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Installing: $dpkg_name"
    sudo apt install -y $dpkg_name
  fi
}

#---------------------------------------------------------------------------------------