#!/bin/bash
# auto_upgrade.sh - A proxy script to quickly setup/upgrade Geth, Beacon, Validator, Clientstats
# Run: ./auto_upgrade.sh or setup as cronjob task
# Author: Max Vuong
# Date: 12/02/2021

# ---------------------------------------------------------------
# README
# ---------------------------------------------------------------

: <<'COMMENT_BLOCK'
Instructions to install and automate node upgrade for Beacon, Validator, Clientstats, Mevboost, and Geth:
 
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

COMMENT_BLOCK

# ---------------------------------------------------------------
# END README
# ---------------------------------------------------------------

echo "Auto Upgrade is in progress..."

# ---------------------------------------------------------------

source <(curl -s https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/refs/heads/master/scripts/lib.sh)

# ---------------------------------------------------------------

bash <(curl -s $GITHUB_REPO_URI/node_upgrade.sh)