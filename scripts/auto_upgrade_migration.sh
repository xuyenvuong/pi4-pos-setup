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
DISCORD_WEBHOOK_URL=$(cat auto_upgrade.sh | grep ^DISCORD_WEBHOOK_URL)
GETH_PRUNE_AT_PERCENTAGE=$(cat auto_upgrade.sh | grep ^GETH_PRUNE_AT_PERCENTAGE)

mv ~/auto_upgrade.sh /tmp/auto_upgrade.sh.$(date "+%Y%m%d-%H%M%S")
wget https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/auto_upgrade.sh && chmod +x auto_upgrade.sh

sed -i "s|^DISCORD_WEBHOOK_URL=''|$DISCORD_WEBHOOK_URL|g" ~/auto_upgrade.sh
sed -i "s|^GETH_PRUNE_AT_PERCENTAGE=90|$GETH_PRUNE_AT_PERCENTAGE|g" ~/auto_upgrade.sh

# ---------------------------------------------------------------