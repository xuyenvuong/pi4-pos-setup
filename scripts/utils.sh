#!/bin/bash
# utils.sh - A script to provide quick maintenance work
# Author: Max Vuong
# Last update: 20260601

: <<'COMMENT_BLOCK'
Instructions to run the utils script:

Run:
> bash <(curl -s https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/refs/heads/master/scripts/utils.sh)

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

#-------------------------------------------------------------------------------------------#

# Perform prune history
function perform_prune_history() {
  

}

#-------------------------------------------------------------------------------------------#
# Utils prompt
#-------------------------------------------------------------------------------------------#

PS3='Please enter your command choice: '
options=("Prune History""Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Prune History")            
            echo "Installing $opt"
            perform_prune_history
            ;;
        "Quit")
            echo "Good bye!"
            break
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done

source ~/.bashrc
