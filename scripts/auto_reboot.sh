#!/bin/bash
# auto_reboot.sh - A script to local detect internet and reboot if unable to ping www.google.com
# chmod +x /srv/auto_reboot.sh 
# 5 * * * * /srv/auto_reboot.sh - Add to contab to run each 5 mins
# Author: Max Vuong
# Date: 01/21/2023

# Restart only if uncommunicative
if ! ping -c5 www.google.com ; then
  logger "Auto rebooting due to internet connection."
  sudo shutdown -r now  
fi