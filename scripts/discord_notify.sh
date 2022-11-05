#!/bin/bash
# discord_notify.sh - A script to send a Discord msg.
# Run: ./discord_notify.sh "message string as param"
# Author: Max Vuong
# Date: 11/05/2022

# ---------------------------------------------------------------
# README
# ---------------------------------------------------------------

: <<'COMMENT_BLOCK'
Instructions to download the script:
 
One time download from repo:
Run:
> wget https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/discord_notify.sh && chmod +x discord_notify.sh

COMMENT_BLOCK

# ---------------------------------------------------------------
# END README
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# Discord Notification Webhook Config
# ---------------------------------------------------------------


DISCORD_WEBHOOK_URL=''


# ---------------------------------------------------------------
# Other configs
# ---------------------------------------------------------------

HOSTNAME=$(hostname)
PROCESS_NAME="auto_upgrade_$HOSTNAME"

# ---------------------------------------------------------------
# To send a simple notification to Discord via webhook. This function only send when DISCORD_WEBHOOK_URL variable is not null
# discord_notify $username $msg_content

function discord_notify() {
  local username=$1
  local msg_content=$2  
    
  if [ -n "$DISCORD_WEBHOOK_URL" ]; then
    curl -H "Content-Type: application/json" -X POST -d "{\"username\": \"$username\",\"content\": \"$msg_content\"}" $DISCORD_WEBHOOK_URL
  fi  
}

# ---------------------------------------------------------------

discord_notify $PROCESS_NAME "$*"