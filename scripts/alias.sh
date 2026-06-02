#!/bin/bash
# alias.sh - A script to shorten the linux command for your convinient.
# Author: Max Vuong
# Date: 04/28/2022

: <<'COMMENT_BLOCK'
Run this command to add aliases to your .bashrc
> bash <(curl -s https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/alias.sh)

Description:
Supporting services [mevboost, beacon, validator, eth2-stats, geth, prometheus, prometheus-node-exporter, grafana]
Supporting post-fixes [-log, -start, -stop, -restart, -enable]
Supporting post-fixes beacon-syncing, geth-syncing

Usage: 
Add post-fixes after your service name [service][-postfix].
Example: "beacon-log", "validator-restart", "geth-stop', ect...

Test, view beacon log by typing at the command prompt:
> beacon-log

COMMENT_BLOCK

# ---------------------------------------------------------------

source <(curl -s https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/refs/heads/master/scripts/lib.sh)

#-------------------------------------------------------------------------------------------#

install_package ccze

# ---------------------------------------------------------------

# echo "Clean up .bashrc aliases"

# sudo sed -i "/Aliases/d" ~/.bashrc
# sudo sed -i "/beacon/d" ~/.bashrc
# sudo sed -i "/validator/d" ~/.bashrc
# sudo sed -i "/eth2/d" ~/.bashrc
# sudo sed -i "/geth/d" ~/.bashrc
# sudo sed -i "/prometheus/d" ~/.bashrc
# sudo sed -i "/grafana/d" ~/.bashrc
# sudo sed -i "/mevboost/d" ~/.bashrc
# sudo sed -i "/node-/d" ~/.bashrc
# # Replace multiples blank lines with one blank line
# sudo sed -i "\$!N;/^\n\$/{\$q;D;};P;D;" ~/.bashrc

# ---------------------------------------------------------------

echo "Adding aliases to .bash_aliases file"

# sudo cat << EOF | sudo tee -a $HOME/.bashrc >/dev/null
sudo cat << EOF | sudo tee -a ~/.bash_aliases >/dev/null
# Aliases for Node
alias beacon-log='journalctl -f -u prysm-beacon.service -n 200 | ccze -A'
alias validator-log='journalctl -f -u prysm-validator.service -n 200 | ccze -A'
alias eth2-stats-log='journalctl -f -u eth2-client-metrics-exporter.service -n 200 | ccze -A'
alias geth-log='journalctl -f -u geth.service -n 200 | ccze -A'
alias prometheus-log='journalctl -f -u prometheus -n 200 | ccze -A'
alias prometheus-node-exporter-log='journalctl -f -u prometheus-node-exporter -n 200 | ccze -A'
alias grafana-log='journalctl -f -u grafana-server -n 200 | ccze -A'
alias mevboost-log='journalctl -f -u mevboost.service -n 200 | ccze -A'

alias beacon-start='sudo systemctl start prysm-beacon.service'
alias validator-start='sudo systemctl start prysm-validator.service'
alias eth2-stats-start='sudo systemctl start eth2-client-metrics-exporter.service'
alias geth-start='sudo systemctl start geth.service'
alias prometheus-start='sudo systemctl start prometheus'
alias prometheus-node-exporter-start='sudo systemctl start prometheus-node-exporter'
alias grafana-start='sudo systemctl start grafana-server'
alias mevboost-start='sudo systemctl start mevboost.service'

alias beacon-stop='sudo systemctl stop prysm-beacon.service'
alias validator-stop='sudo systemctl stop prysm-validator.service'
alias node-exporter-stop='sudo systemctl stop eth2-client-metrics-exporter.service'
alias geth-stop='sudo systemctl stop geth.service'
alias prometheus-stop='sudo systemctl stop prometheus'
alias prometheus-node-exporter-stop='sudo systemctl stop prometheus-node-exporter'
alias grafana-stop='sudo systemctl stop grafana-server'
alias mevboost-stop='sudo systemctl stop mevboost.service'

alias beacon-restart='sudo systemctl restart prysm-beacon.service'
alias validator-restart='sudo systemctl restart prysm-validator.service'
alias eth2-stats-restart='sudo systemctl restart eth2-client-metrics-exporter.service'
alias geth-restart='sudo systemctl restart geth.service'
alias prometheus-restart='sudo systemctl restart prometheus'
alias prometheus-node-exporter-restart='sudo systemctl restart prometheus-node-exporter'
alias grafana-restart='sudo systemctl restart grafana-server'
alias mevboost-restart='sudo systemctl restart mevboost.service'

alias beacon-enable='sudo systemctl enable prysm-beacon.service'
alias validator-enable='sudo systemctl enable prysm-validator.service'
alias eth2-stats-enable='sudo systemctl enable eth2-client-metrics-exporter.service'
alias geth-enable='sudo systemctl enable geth.service'
alias prometheus-enable='sudo systemctl enable prometheus'
alias prometheus-node-exporter-enable='sudo systemctl enable prometheus-node-exporter'
alias grafana-enable='sudo systemctl enable grafana-server'
alias mevboost-enable='sudo systemctl enable mevboost.service'

alias beacon-disable='sudo systemctl disable prysm-beacon.service'
alias validator-disable='sudo systemctl enadisableble prysm-validator.service'
alias eth2-stats-disable='sudo systemctl disable eth2-client-metrics-exporter.service'
alias geth-disable='sudo systemctl disable geth.service'
alias prometheus-disable='sudo systemctl disable prometheus'
alias prometheus-node-exporter-disable='sudo systemctl disable prometheus-node-exporter'
alias grafana-disable='sudo systemctl disable grafana-server'
alias mevboost-disable='sudo systemctl disable mevboost.service'

alias beacon-config="vi prysm/configs/beacon.yaml"
alias validator-config="vi prysm/configs/validator.yaml"
alias geth-config="sudo vi /etc/ethereum/geth.conf"
alias mevboost-config="sudo vi /etc/ethereum/mevboost.conf"

alias geth-version="geth version"
alias mevboost-version='mev-boost -version'

alias beacon-syncing='curl http://localhost:3500/eth/v1/node/syncing'
alias geth-syncing="printf 'eth.syncing' | /usr/local/bin/geth attach http://localhost:8545"
alias geth-peers="printf 'net.peerCount' | /usr/local/bin/geth attach http://localhost:8545"

alias node-upgrade='./auto_upgrade.sh'
alias node-auto-upgrade-latest='rm auto_upgrade.sh && wget https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/auto_upgrade.sh && chmod +x auto_upgrade.sh'
alias node-aliases-latest='bash <(curl -s https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/alias.sh)'
alias node-go-lib-latest='bash <(curl -s https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/upgrade_go_lib.sh)'
alias node-health='curl http://localhost:8080/healthz'
alias node-utils='bash <(curl -s https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/refs/heads/master/scripts/utils.sh)'
EOF

source ~/.bashrc