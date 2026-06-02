#!/bin/bash
# lib.sh - Common useful function


: <<'COMMENT_BLOCK'
Instructions to run the lib script:

Include this line to other script:
> source <(curl -s https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/refs/heads/master/scripts/lib.sh)

COMMENT_BLOCK

#-------------------------------------------------------------------------------------------#

set -eu

ARCH=$(dpkg --print-architecture)

#-------------------------------------------------------------------------------------------#

# Install package
function install_package() {
  local dpkg_name=$1

  if [ $(dpkg-query -W -f='${Status}' $dpkg_name 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Installing: $dpkg_name"
    sudo apt install -y $dpkg_name
  fi
}

#---------------------------------------------------------------------------------------

# To send a simple notification to Discord via webhook. This function only send when DISCORD_WEBHOOK_URL variable is not null
# discord_notify $msg_content

function discord_notify() {
  if [ -e /srv/discord_notify.sh ]; then
    /srv/discord_notify.sh "$*"
  fi
}

# ---------------------------------------------------------------