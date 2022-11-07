#!/bin/bash
# auto_upgrade_migration.sh - A script to update and migrate auto_upgrade.sh
# Author: Max Vuong
# Date: 09/13/2022

: <<'COMMENT_BLOCK'
Run this command to update and migrate the auto_upgrade.sh script
> curl -L https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/auto_upgrade_migration.sh | bash

COMMENT_BLOCK

# ---------------------------------------------------------------
cd ~

GITHUB_REPO_URI=https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts

DISCORD_WEBHOOK_URL=''
GETH_PRUNE_AT_PERCENTAGE=''

# Migrate file to /srv
if [ -e ~/discord_notify.sh ]; then
  sudo mv ~/discord_notify.sh /srv
fi

if [ -e /srv/discord_notify.sh ]; then
  DISCORD_WEBHOOK_URL=$(cat /srv/discord_notify.sh | grep ^DISCORD_WEBHOOK_URL)
  
  # Remove /srv/discord_notify.sh
  sudo mv /srv/discord_notify.sh /tmp/discord_notify.sh.$(date "+%Y%m%d-%H%M%S")
else
  DISCORD_WEBHOOK_URL=$(cat ~/auto_upgrade.sh | grep ^DISCORD_WEBHOOK_URL)
fi

if [ -e ~/auto_upgrade.sh ]; then
  GETH_PRUNE_AT_PERCENTAGE=$(cat ~/auto_upgrade.sh | grep ^GETH_PRUNE_AT_PERCENTAGE)
  
  # Remove auto_upgrade.sh
  mv ~/auto_upgrade.sh /tmp/auto_upgrade.sh.$(date "+%Y%m%d-%H%M%S")
fi

# Get latest version of discord_notify.sh script
sudo wget -P /srv $GITHUB_REPO_URI/discord_notify.sh && sudo chmod +x /srv/discord_notify.sh

# Get latest version of auto_upgrade.sh script
wget $GITHUB_REPO_URI/auto_upgrade.sh && chmod +x ~/auto_upgrade.sh

if [[ $DISCORD_WEBHOOK_URL ]]; then
  sudo sed -i "s|^DISCORD_WEBHOOK_URL=''|$DISCORD_WEBHOOK_URL|g" /srv/discord_notify.sh
fi

if [[ $GETH_PRUNE_AT_PERCENTAGE ]]; then
  sed -i "s|^GETH_PRUNE_AT_PERCENTAGE=90|$GETH_PRUNE_AT_PERCENTAGE|g" ~/auto_upgrade.sh
fi

# ---------------------------------------------------------------