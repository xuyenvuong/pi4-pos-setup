#!/bin/bash
# setup.sh - A script to quickly setup ETH PoS node
# Author: Max Vuong

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

PRYSM_SH_URL=https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh

DEPOSIT_CLI_RELEASES_LATEST=https://api.github.com/repos/ethereum/staking-deposit-cli/releases/latest

ETH2_CLIENT_METRICS_EXPORTER_RELEASES_LATEST=https://api.github.com/repos/gobitfly/eth2-client-metrics-exporter/releases/latest

# GETH_RELEASES_LATEST=https://api.github.com/repos/ethereum/go-ethereum/releases/latest

GETH_TAGS_URL=https://api.github.com/repos/ethereum/go-ethereum/tags

AUTO_UPGRADE_URL=https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/auto_upgrade_migration.sh

NOIP_URL=https://www.noip.com/client/linux/noip-duc-linux.tar.gz

GO_LATEST_VERSION_JSON=https://go.dev/dl/?mode=json

GO_BIN_DOWNLOAD_URL=https://go.dev/dl/

PROMETHEUS_RELEASES_LATEST=https://api.github.com/repos/prometheus/prometheus/releases/latest

NODE_EXPORTER_RELEASES_LATEST=https://api.github.com/repos/prometheus/node_exporter/releases/latest

ARCH=$(dpkg --print-architecture)

#-------------------------------------------------------------------------------------------#
# Main function to install all necessary package to support the node
function install_essential() {
  # Update & Upgrade to latest
  sudo apt update && sudo apt upgrade
  sudo apt dist-upgrade
  sudo apt autoremove
  
  #---------------------------------------------#
  #  BASIC REQUIREMENTS
  #---------------------------------------------#
  
  # Independent packages  
  install_package vim
  install_package git-all
  install_package zip
  install_package unzip
  install_package make
  install_package gcc
  install_package build-essential
  install_package libssl-dev
  install_package libffi-dev
  install_package chrony
  install_package jq
  install_package tmux
  install_package ccze
  install_package net-tools  

  # Chrony  
  config_chrony

  # Populate folders
  populate_folders

  # Category: Stats | Prometheus Node Exporter
  install_prometheus_node_exporter
  config_prometheus_node_exporter

  # Category: Stats | Eth2 Client Metrics Exporter
  install_eth2_client_metrics_exporter
  config_eth2_client_metrics_exporter

  # Go
  install_go

  # GETH
  install_geth
  config_geth

  # Prysm
  install_prysm
  config_beacon
  config_validator

  # Validator key generator
  install_validator_key_generator

  # Mevboost
  install_mevboost

  # Auto Upgrade to the latest version scripts
  install_auto_upgrade

  # Aliases
  config_aliases

  # JWT for geth and beacon
  config_auth_jwt

  # Logs
  config_logrotate

  # Discord
  config_discord_notify

  # Firewall Ports
  config_ports

  # Power button disabling
  config_disable_power_button

  #---------------------------------------------#
  #  OPTIONAL INSTALLATION
  #---------------------------------------------#

  # Category: Stats | Prometheus  
  install_prometheus
  config_prometheus  

  # Category: Stats | Grafana
  install_grafana
  config_grafana

  # Category: DDNS - NO-IP (optional)
  install_noip
  config_noip

  # Category: DDNS - ddclient (optional)
  install_ddclient
  config_ddclient

  # Category: Security - Google Auth (optional)
  install_google_authenticator

  # Category: Security - Yubikey (optional)  
  install_yubikey
  config_ssh_yubikey_auth

  # Category: Stats - Prysm stats (optional)
  systemd_clientstats
  
  # Category: Network - Resolver (optional)
  config_systemd_resolved
}

# Install Prometheus latest
function install_prometheus() {
  # https://computingforgeeks.com/install-prometheus-server-on-debian-ubuntu-linux/
  if [ $(dpkg-query -W -f='${Status}' prometheus 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    sudo groupadd --system prometheus
    sudo useradd -s /sbin/nologin --system -g prometheus prometheus
    sudo mkdir /etc/prometheus
    sudo mkdir /var/lib/prometheus

    for i in rules rules.d files_sd; do sudo mkdir -p /etc/prometheus/${i}; done
    
    rm -rf /tmp/prometheus-*

    prometheus_download_url=$(wget -O - -o /dev/null $PROMETHEUS_RELEASES_LATEST | jq '.assets[].browser_download_url' | grep linux-$ARCH | tr -d \")
    wget -P /tmp $prometheus_download_url

    cd /tmp
    tar xvf prometheus*.tar.gz
    cd prometheus*64
    sudo mv prometheus promtool /usr/local/bin/
    prometheus --version
    sudo mv prometheus.yml /etc/prometheus/prometheus.yml
    sudo mv consoles/ console_libraries/ /etc/prometheus/
    cd
  fi
}

# Install Prometheus Node Exporter
function install_prometheus_node_exporter() {
  # https://ourcodeworld.com/articles/read/1686/how-to-install-prometheus-node-exporter-on-ubuntu-2004
  if [ $(dpkg-query -W -f='${Status}' prometheus-node-exporter 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    node_exporter_download_url=$(wget -O - -o /dev/null $NODE_EXPORTER_RELEASES_LATEST | jq '.assets[].browser_download_url' | grep linux-$ARCH | tr -d \")
    
    rm -rf /tmp/node_exporter-*
    wget -P /tmp $node_exporter_download_url
    
    cd /tmp
    tar xvf node_exporter-*
    cd node_exporter-*64
    sudo cp node_exporter /usr/local/bin

    sudo useradd --no-create-home --shell /bin/false node_exporter
    sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
  fi
}

# Install Go
function install_go() {
  go_latest_version=$(wget -O - -o /dev/null $GO_LATEST_VERSION_JSON | jq '.[0].files | .[] | select(.os=="linux" and .arch=="'$ARCH'") | .filename'  | tr -d \")

  go_bin_tar_url="$GO_BIN_DOWNLOAD_URL$go_latest_version"
  wget -P /tmp $go_bin_tar_url
  
  sudo rm -rvf /usr/local/go
  sudo tar -xvf /tmp/$go_latest_version -C /usr/local

  rm -rf /tmp/$go_latest_version

  sudo sed -i "/GoLang/d" ~/.bashrc
  sudo sed -i "/GOROOT/d" ~/.bashrc
  sudo sed -i "/GOPATH/d" ~/.bashrc

  # Replace multiples blank lines with one blank line
  sudo sed -i "$!N;/^\n$/{$q;D;};P;D;" ~/.bashrc

  sudo cat << EOF | sudo tee -a ~/.bashrc >/dev/null
# GoLang
export GOROOT=/usr/local/go
export GOPATH=~/go
export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH
EOF

  source ~/.bashrc
  go version
}

# Install Grafana
function install_grafana() {
  if [ $(dpkg-query -W -f='${Status}' grafana-enterprise 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    install_package apt-transport-https
    install_package software-properties-common
    
    sudo mkdir -m 0755 -p /etc/apt/keyrings/
    wget -q -O - https://apt.grafana.com/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
        
    sudo apt update
    
    install_package grafana-enterprise
  fi

  # Next steps are optional, use nginx to override the local domain name instead.
  sudo openssl genrsa -out /etc/grafana/grafana.key 2048  
  sudo openssl req -new -key /etc/grafana/grafana.key -out /etc/grafana/grafana.csr
  
  # Leave empty when prompt except Common Name: 'localhost' 

  sudo openssl x509 -req -days 365 -in /etc/grafana/grafana.csr -signkey /etc/grafana/grafana.key -out /etc/grafana/grafana.crt
  
  sudo chown grafana:grafana /etc/grafana/grafana.crt
  sudo chown grafana:grafana /etc/grafana/grafana.key
  sudo chmod 400 /etc/grafana/grafana.key /etc/grafana/grafana.crt

  sudo vi /etc/grafana/grafana.ini
  # Edit:
  # http_addr =
  # http_port = 3000
  # domain = mysite.com
  # root_url = https://subdomain.mysite.com:3000
  # cert_key = /etc/grafana/grafana.key
  # cert_file = /etc/grafana/grafana.crt
  # enforce_domain = False
  # protocol = https

  grafana-restart
}

# Install Eth2 Client Metrics Exporter
function install_eth2_client_metrics_exporter() {
  if [ ! -e /usr/local/bin/eth2-client-metrics-exporter ]; then    
    curl -s $ETH2_CLIENT_METRICS_EXPORTER_RELEASES_LATEST | grep "eth2-client-metrics-exporter-linux-$ARCH" | cut -d : -f 2,3 |  tr -d \" | wget -qi - -O /tmp/eth2-client-metrics-exporter
    chmod +x /tmp/eth2-client-metrics-exporter
    sudo mv /tmp/eth2-client-metrics-exporter /usr/local/bin
  fi 
}

# Install GETH
function install_geth() {  
  if [ ! -e /usr/local/bin/geth ]; then
    # Download latest GETH info
    geth_latest_version=$(wget -O - -o /dev/null $GETH_TAGS_URL | jq '.[0].name' | tr -d \" | cut -c 2-)
    
    sha=$(wget -O - -o /dev/null $GETH_TAGS_URL | jq '.[0].commit.sha' | cut -c 2-9)
    download_version=$ARCH-$geth_latest_version-$sha
    
    # Download latest tar ball and move to bin folder
    wget -P /tmp https://gethstore.blob.core.windows.net/builds/geth-linux-$download_version.tar.gz
    tar -C /tmp -xvf /tmp/geth-linux-$download_version.tar.gz
    sudo cp /tmp/geth-linux-$download_version/geth /usr/local/bin
  fi
}

# Install Mevboost
function install_mevboost() {
  /usr/local/go/bin/go install github.com/flashbots/mev-boost@latest
  sudo cp ~/go/bin/mev-boost /usr/local/bin
}

function install_auto_upgrade() {
  if [ ! -e ~/auto_upgrade.sh ]; then
    curl -L $AUTO_UPGRADE_URL | bash
  fi
}

# Install Prysm
function install_prysm() {
  if [ ! -e ~/prysm/prysm.sh ]; then
    curl $PRYSM_SH_URL --output ~/prysm/prysm.sh && chmod +x ~/prysm/prysm.sh
  fi
}

# Install Validator Key Generator
function install_validator_key_generator() {
  if [ ! -e ~/staking_deposit-cli-*-linux-amd64/deposit ]; then    
    rm -rf /tmp/staking_deposit-cli-*

    browser_download_url=$(wget -O - -o /dev/null $DEPOSIT_CLI_RELEASES_LATEST | jq '.assets[].browser_download_url' | grep linux-$ARCH | tr -d \")
    wget -P /tmp $browser_download_url
    
    tar -C ~ -xzvf /tmp/staking_deposit-cli-*.tar.gz
  fi

  # Download via Github GUI
  # https://github.com/ethereum/staking-deposit-cli/releases
  
  #-----------------------------------------------------------------#
  # To run:
  # > cd staking_deposit-cli-*-linux-amd64
  # > ./deposit new-mnemonic --num_validators 1 --chain mainnet
  # At prompt, enter the seeds pharse, then 
  # At prompt follow by enter ACCOUNT PASSWORD, Save it to Bitwarden
  
  #-----------------------------------------------------------------#
  # To Import Keys
  # > prysm/prysm.sh validator accounts import --keys-dir=~/staking_deposit-cli-*-linux-amd64/validator_keys --mainnet --accept-terms-of-use
  # Input wallet path
	# Prompt> ~/.wallet/prysm-wallet-v2
  # Input wallet password
	# Prompt> (NOTE: Save the WALLET PASSWORD to Bitwarden)
  # Input Account password (from key generator step)
	# Prompt> (NOTE: Save the ACCOUNT PASSWORD to Bitwarden)
  # Add wallet password to password.txt file
  
	# > vi .password/password.txt
  
  #-----------------------------------------------------------------#  
  # Generate additional keys
  # ./deposit existing-mnemonic --num_validators 1 --chain mainnet
  # At prompt, enter ACCOUNT PASSWORD
  
  # Import Additional Keys
  # > prysm/prysm.sh validator accounts import --wallet-dir=~/.wallet/prysm-wallet-v2 --keys-dir=~/validator_keys_mainnet.xx_xx_keys --mainnet --accept-terms-of-use
  # At prompt, enter the WALLET PASSWORD, then 
  # At prompt, follow by ACCOUNT PASSWORD
  
  #-----------------------------------------------------------------#
}

# Install NOIP Service
function install_noip() {
  if [ ! -e /usr/local/bin/noip2 ]; then
    wget -P /tmp $NOIP_URL
    tar -C /tmp -xvf /tmp/noip-duc-linux.tar.gz
    cd /tmp/noip-2.1.9-1/

    sudo make
    sudo make install

    sudo cp noip2 /usr/local/bin
    /usr/local/bin/noip2 -C -c /tmp/no-ip2.conf
    sudo mv /tmp/no-ip2.conf /usr/local/etc/no-ip2.conf
  fi
}

# Install ddclient Service
function install_ddclient() {
  if [ ! -e /usr/sbin/ddclient ]; then
    sudo apt install ddclient

    #1. Select "other"
    #2. Enter "freemyip.com"
    #3. Select "dyndns2"
    #4. Enter freemyip.com token for username      
    #5. Enter freemyip.com token for password
    #6. Network interface empty
    #7. Enter your full domain name: e.g. mvuong.freemyip.com
  fi
}

# Install Google Authenticator
function install_google_authenticator() {
  if [ $(dpkg-query -W -f='${Status}' libpam-google-authenticator 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Installing: libpam-google-authenticator"

    sudo vi /etc/ssh/sshd_config
    Set: 
      # ChallengeResponseAuthentication yes (has been replaced with the below cmd)
      KbdInteractiveAuthentication yes
    
    
    sudo apt install libpam-google-authenticator
    google-authenticator

    # (Backup the info)
    # (Answer “Y” when asked whether Google Authenticator should update your .google_authenticator file.
    # Then answer “Y” to disallow multiple uses of the same authentication token, 
    # “N” to increase the time skew window, 
    # and “Y” to rate limiting in order to protect against brute-force attacks.)

    sudo vi /etc/pam.d/sshd
    # (Add new line after @include common-auth)
    >>> auth required pam_google_authenticator.so

    sudo systemctl restart ssh
  fi
}

# Install Yubikey
function install_yubikey() {
  # https://monicalent.com/blog/2017/12/16/ssh-via-yubikeys-ubuntu/

  if [ $(dpkg-query -W -f='${Status}' libpam-yubico 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Installing: libpam-yubico"

    sudo add-apt-repository ppa:yubico/stable
    sudo apt-get update
    install_package libpam-yubico

    # Generate key here: https://upgrade.yubico.com/getapikey/
    # Client ID: XXXXX
    # Secret Key: xxxxxxxxxxxxxxxxxxxx

    sudo vi /etc/pam.d/sshd

    >>> auth required pam_yubico.so id=[Your Client ID] key=[Your Secret Key] debug authfile=/etc/yubikey_mappings mode=client

    # Disable @include common-auth and Google Authenticator

    sudo vi /etc/yubikey_mappings
    >>> username:first12digitofkey1:first12digitofkey2
    # username e.g. ubuntu

    sudo vi /etc/ssh/sshd_config
    Set:
      PubkeyAuthentication yes
      AuthorizedKeysFile      %h/.ssh/authorized_keys
      PubkeyAcceptedKeyTypes +ssh-rsa
      PasswordAuthentication no
      ChallengeResponseAuthentication yes
      >>> AuthenticationMethods publickey,keyboard-interactive:pam

    vi .ssh/authorized_keys
    # Add publickeys (for PC and Android)
    # Generate PC key with PuTTYGen: https://www.hostinger.com/tutorials/vps/how-to-generate-ssh-keys-on-putty
    # -- If key error, check this https://mulcas.com/couldnt-load-private-key-putty-key-format-too-new/
    # Generate Android key with OpenSSH: https://phoenixnap.com/kb/generate-ssh-key-windows-10
    # Run
    #   ssh-keygen -m PEM -P "" -t rsa
    
    sudo systemctl restart ssh
    
    # Config puTTy to load private key from PC Keys folder
    # Config JuiceSSH to laod private key from Android Keys folder

  fi
}

#-------------------------------------------------------------------------------------------#
# Initialize folders setup: important files/directories in order to run the PoS node
function populate_folders() {   
  # Define setup directories
  mkdir -p ~/{.eth2,.wallet,.password,logs,prysm,prysm/configs}
  sudo mkdir -p /etc/ethereum
  sudo mkdir -p /home/prometheus/node-exporter
  
  # Create files
  touch ~/.password/password.txt
  touch ~/logs/{beacon,validator}.log
}

#-------------------------------------------------------------------------------------------#
# Config Files
#-------------------------------------------------------------------------------------------#

# Config auth JWT
function config_auth_jwt() {
  if [ ! -e /etc/ethereum/jwt.hex ]; then
    openssl rand -hex 32 | tr -d "\n" | sudo tee /etc/ethereum/jwt.hex >/dev/null
  fi
}

# Systemd Beacon Service
function config_beacon() {
  if [ ! -e /etc/systemd/system/prysm-beacon.service ]; then
    sudo cat << EOF | sudo tee /etc/systemd/system/prysm-beacon.service >/dev/null
[Unit]
Description=Prysm Beacon Daemon
After=network.target auditd.service
Requires=network.target

[Service]
EnvironmentFile=/etc/ethereum/prysm-beacon.conf
Environment=USE_PRYSM_MODERN=$(if [ $(lscpu | grep -wc adx) -eq 1 ]; then echo "true"; else echo "false"; fi)
ExecStart=$HOME/prysm/prysm.sh \$ARGS
Restart=always
RestartSec=10
User=$USER

[Install]
WantedBy=multi-user.target
Alias=prysm-beacon.service
EOF
  fi
  
  # EnvironmentFile
  if [ ! -e /etc/ethereum/prysm-beacon.conf ]; then
    sudo cat << EOF | sudo tee /etc/ethereum/prysm-beacon.conf >/dev/null
ARGS="beacon-chain
 --mainnet
 --accept-terms-of-use
 --config-file=$HOME/prysm/configs/beacon.yaml
"
EOF
  fi
  
  # YAML
  if [ ! -e ~/prysm/configs/beacon.yaml ]; then
    sudo cat << EOF | tee ~/prysm/configs/beacon.yaml >/dev/null
datadir: "/mnt/ssdxxxx/beacon"
log-file: "$HOME/logs/beacon.log"

# Mainnet Contract
deposit-contract: 0x00000000219ab540356cbb839cbe05303d7705fa
contract-deployment-block: 11052984

verbosity: info

execution-endpoint: http://localhost:8551

jwt-secret: /etc/ethereum/jwt.hex

attest-timely: true

# Sync faster (default 64)
block-batch-limit: 128

#p2p-host-ip: $(curl -s v4.ident.me)
p2p-host-dns: "mvuong.freemyip.com"

p2p-tcp-port: 13000
p2p-udp-port: 12000
p2p-quic-port: 13001

p2p-max-peers: 100
min-sync-peers: 3

rpc-port: 4000
rpc-host: 0.0.0.0

monitoring-port: 8080
monitoring-host: 0.0.0.0

update-head-timely: true

suggested-fee-recipient: 0x__YOUR_WALLET_ADDRESS__

# Mev Boost
http-mev-relay: http://localhost:18550

# Faster sync
checkpoint-sync-url: https://sync-mainnet.beaconcha.in
genesis-beacon-api-url: https://sync-mainnet.beaconcha.in

rpc-max-page-size: 200000
grpc-max-msg-size: 268435456

# 12s is the upper bound
engine-endpoint-timeout-seconds: 10

aggregate-first-interval: 7500ms
aggregate-second-interval: 9800ms
aggregate-third-interval: 11900ms

blob-save-fsync: true
enable-minimal-slashing-protection: true
save-invalid-block-temp: true

# Optional
local-block-value-boost: 5

suggested-gas-limit: 36000000
EOF
  fi

  # Check beacon sync status
  # curl http://localhost:3500/eth/v1/node/syncing
}

# Systemd Validator Service
function config_validator() {
  if [ ! -e /etc/systemd/system/prysm-validator.service ]; then
    sudo cat << EOF | sudo tee /etc/systemd/system/prysm-validator.service >/dev/null    
[Unit]
Description=Prysm Validator Daemon
After=network.target auditd.service
Requires=network.target

[Service]
EnvironmentFile=/etc/ethereum/prysm-validator.conf
ExecStart=$HOME/prysm/prysm.sh \$ARGS
Restart=always
RestartSec=10
User=$USER

[Install]
WantedBy=multi-user.target
Alias=prysm-validator.service
EOF
  fi
  
  # EnvironmentFile
  if [ ! -e /etc/ethereum/prysm-validator.conf ]; then
    sudo cat << EOF | sudo tee /etc/ethereum/prysm-validator.conf >/dev/null
ARGS="validator
 --mainnet
 --accept-terms-of-use
 --config-file=$HOME/prysm/configs/validator.yaml
"
EOF
  fi
  
  # YAML
  if [ ! -e ~/prysm/configs/validator.yaml ]; then
    sudo cat << EOF | tee ~/prysm/configs/validator.yaml >/dev/null
datadir: "/mnt/ssdxxxx/validator"
log-file: "$HOME/logs/validator.log"

verbosity: info

wallet-dir: "$HOME/.wallet/prysm-wallet-v2"
wallet-password-file: "$HOME/.password/password.txt"

beacon-rpc-provider: localhost:4000,host1:port,host2:port

attest-timely: true

enable-slashing-protection-history-pruning: true
enable-external-slashing-protection: true
enable-doppelganger: true

monitoring-port: 8081
monitoring-host: 0.0.0.0

suggested-fee-recipient: ______0xYOUR_WALLET_ADDRESS______

enable-builder: true
EOF
  fi
}

# Config Prometheus Node Exporter
function config_prometheus_node_exporter() {
  if [ ! -e /etc/systemd/system/prometheus-node-exporter.service ]; then
    sudo cat << EOF | sudo tee /etc/systemd/system/prometheus-node-exporter.service >/dev/null
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF 

    sudo systemctl daemon-reload
    sudo systemctl enable prometheus-node-exporter
    sudo systemctl start prometheus-node-exporter

    # Note: open port 9100
  fi
}

# Config Mevboost
function config_mevboost() {
  if [ ! -e /etc/systemd/system/mevboost.service ]; then
    sudo cat << EOF | sudo tee /etc/systemd/system/mevboost.service >/dev/null
[Unit]
Description=Mev-Boost Daemon
After=network.target auditd.service
Requires=network.target

[Service]
EnvironmentFile=/etc/ethereum/mevboost.conf
ExecStart=mev-boost \$ARGS
Restart=always
RestartSec=3
User=$USER

[Install]
WantedBy=multi-user.target
Alias=mevboost.service
EOF
  fi

  if [ ! -e /etc/systemd/system/mevboost.service ]; then
    sudo cat << EOF | sudo tee /etc/ethereum/mevboost.conf >/dev/null
ARGS="
 -mainnet
 -relay-check
 -loglevel debug
 -request-timeout-getheader 1000
 -request-timeout-getpayload 4000
 -request-timeout-regval 4000
 -min-bid 0.02
 -relay https://0xa15b52576bcbf1072f4a011c0f99f9fb6c66f3e1ff321f11f461d15e31b1cb359caa092c71bbded0bae5b5ea401aab7e@aestus.live
 -relay https://0xa7ab7a996c8584251c8f925da3170bdfd6ebc75d50f5ddc4050a6fdc77f2a3b5fce2cc750d0865e05d7228af97d69561@agnostic-relay.net
 -relay https://0x8b5d2e73e2a3a55c6c87b8b6eb92e0149a125c852751db1422fa951e42a09b82c142c3ea98d0d9930b056a3bc9896b8f@bloxroute.max-profit.blxrbdn.com
 -relay https://0xb0b07cd0abef743db4260b0ed50619cf6ad4d82064cb4fbec9d3ec530f7c5e6793d9f286c4e082c0244ffb9f2658fe88@bloxroute.regulated.blxrbdn.com
 -relay https://0xb3ee7afcf27f1f1259ac1787876318c6584ee353097a50ed84f51a1f21a323b3736f271a895c7ce918c038e4265918be@relay.edennetwork.io
 -relay https://0xac6e77dfe25ecd6110b8e780608cce0dab71fdd5ebea22a16c0205200f2f8e2e3ad3b71d3499c54ad14d6c21b41a37ae@boost-relay.flashbots.net
 -relay https://0x98650451ba02064f7b000f5768cf0cf4d4e492317d82871bdc87ef841a0743f69f0f1eea11168503240ac35d101c9135@mainnet-relay.securerpc.com
 -relay https://0xa1559ace749633b997cb3fdacffb890aeebdb0f5a3b6aaa7eeeaf1a38af0a8fe88b9e4b1f61f236d2e64d95733327a62@relay.ultrasound.money
 -relay https://0x8c7d33605ecef85403f8b7289c8058f440cbb6bf72b055dfe2f3e2c6695b6a1ea5a9cd0eb3a7982927a463feb4c3dae2@relay.wenmerge.com
"
EOF
  fi
}

# Systemd Client Stats Service
function systemd_clientstats() {
  if [ ! -e /etc/systemd/system/prysm-clientstats.service ]; then
    sudo cat << EOF | sudo tee /etc/systemd/system/prysm-clientstats.service >/dev/null
[Unit]
Description=Prysm Client Stats Daemon
After=network.target auditd.service
Requires=network.target

[Service]
EnvironmentFile=/etc/ethereum/prysm-clientstats.conf
ExecStart=$HOME/prysm/prysm.sh \$ARGS
Restart=always
RestartSec=10
User=$USER

[Install]
WantedBy=multi-user.target
Alias=prysm-validator.service
EOF
  fi
  
  # EnvironmentFile
  if [ ! -e /etc/ethereum/prysm-clientstats.conf ]; then
    sudo cat << EOF | sudo tee /etc/ethereum/prysm-clientstats.conf >/dev/null
ARGS="client-stats
 --config-file=$HOME/prysm/configs/clientstats.yaml
 --validator-metrics-url=http://localhost:8081/metrics
 --beacon-node-metrics-url=http://localhost:8080/metrics
 --scrape-interval=1m0s
"
EOF
  fi
}

# Config Eth2 Client Metrics Exporter Service
function config_eth2_client_metrics_exporter() {
  if [ ! -e /etc/systemd/system/eth2-client-metrics-exporter.service ]; then
    sudo cat << EOF | sudo tee /etc/systemd/system/eth2-client-metrics-exporter.service >/dev/null
[Unit]
Description=Eth2 Client Metrics Exporter Daemon
After=network.target auditd.service
Requires=network.target

[Service]
EnvironmentFile=/etc/ethereum/eth2-client-metrics-exporter.conf
ExecStart=/usr/local/bin/eth2-client-metrics-exporter \$ARGS
Restart=always
RestartSec=10
User=$USER

[Install]
WantedBy=multi-user.target
Alias=prysm-validator.service
EOF
  fi
  
  # EnvironmentFile
  if [ ! -e /etc/ethereum/eth2-client-metrics-exporter.conf ]; then
    sudo cat << EOF | sudo tee /etc/ethereum/eth2-client-metrics-exporter.conf >/dev/null
ARGS=" 
 --server.address='https://beaconcha.in/api/v1/client/metrics?apikey=BEACONCHAIN_API_KEY&machine=MACHINE_NAME'
 --beaconnode.type=prysm
 --beaconnode.address=http://localhost:8080/metrics
 --validator.type=prysm
 --validator.address=http://localhost:8081/metrics
"
EOF
  fi
}
  
# Systemd GETH Service
function config_geth() {
  if [ ! -e /etc/systemd/system/geth.service ]; then
    sudo cat << EOF | sudo tee /etc/systemd/system/geth.service >/dev/null
[Unit]
Description=Geth Node Daemon
After=network.target auditd.service
Wants=network.target

[Service]
EnvironmentFile=/etc/ethereum/geth.conf
ExecStart=/usr/local/bin/geth \$ARGS
Restart=always
RestartSec=10
User=$USER

[Install]
WantedBy=multi-user.target
Alias=geth.service
EOF
  fi
  
  # EnvironmentFile
  if [ ! -e /etc/ethereum/geth.conf ]; then
    sudo cat << EOF | sudo tee /etc/ethereum/geth.conf >/dev/null
ARGS="
 --port 30303 
 --http 
 --http.api eth,net,engine,admin,debug,web3
 --http.port 8545 
 --http.addr 0.0.0.0 
 --authrpc.jwtsecret /etc/ethereum/jwt.hex
 --authrpc.addr 0.0.0.0 
 --authrpc.port 8551 
 --authrpc.vhosts * 
 --rpc.batch-response-max-size 50000000
 --syncmode snap 
 --db.engine pebble
 --state.scheme path
 --datadir /mnt/ssdxxxx/chaindata
 --datadir.ancient /mnt/ssdxxxx/ancientdb
 --metrics 
 --metrics.expensive 
 --pprof 
 --pprof.port 6060 
 --pprof.addr 0.0.0.0 
 --maxpeers 100 
 --identity Maximus
 --miner.gaslimit 36000000
"
EOF
  fi

  # Prune geth with tmux
  # /usr/local/bin/geth snapshot prune-state --datadir _CHAINDATA_PATH_

  # Check Geth syncing status
  # /usr/local/bin/geth attach http://localhost:8545
  # > eth.syncing
}  

# Config Prometheus lastest
function config_prometheus() {
  if [ ! -e /etc/systemd/system/prometheus.service ]; then
    sudo cat << EOF | sudo tee /etc/systemd/system/prometheus.service >/dev/null
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle \
  --storage.tsdb.retention.time=31d \
  --web.external-url=

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  fi

  for i in rules rules.d files_sd; do sudo chown -R prometheus:prometheus /etc/prometheus/${i}; done
  for i in rules rules.d files_sd; do sudo chmod -R 775 /etc/prometheus/${i}; done
  sudo chown -R prometheus:prometheus /var/lib/prometheus/

  sudo systemctl daemon-reload
  sudo systemctl start prometheus
  sudo systemctl enable prometheus
  
  # Concat to existing file
  if [ ! -e /etc/prometheus/prometheus.yml ]; then
    sudo cat << EOF | sudo tee -a /etc/prometheus/prometheus.yml >/dev/null

  - job_name: node
    # If prometheus-node-exporter is installed, grab stats about the local
    # machine by default.
    static_configs:
      - targets: ['localhost:9100']

  - job_name: geth
    scrape_interval: 15s
    scrape_timeout: 10s
    metrics_path: /debug/metrics/prometheus
    scheme: http
    static_configs:
      - targets: ['localhost:6060']

  - job_name: 'validator'
    static_configs:
      - targets: ['localhost:8081']

  - job_name: 'beacon node'
    static_configs:
      - targets: ['localhost:8080']

  # - job_name: 'cryptowat'
  #   static_configs:
  #     - targets: ['localhost:9745']
EOF
  fi 
}

# Config Grafana DB
function config_grafana() {
  # Newest Dashboard: https://docs.stakelocal.io/

  # Geth1.0 - Single node
  # https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/sources/Geth_ETH_1.0.json
  # Geth2.0 - Multiple nodes
  # https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/sources/Geth1.0.json
  # Ethereum on AMD node monitor
  # https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/sources/EthereumOnArmAmdNode.json
  # Eth Staking Dashboard
  # https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/sources/EthStakingDashboard.json  

  # Open port 3000/tcp
}

# Config Logrotate
function config_logrotate() {
  if [ ! -e /etc/logrotate.d/prysm-logs ]; then
    sudo cat << EOF | sudo tee /etc/logrotate.d/prysm-logs >/dev/null
$HOME/logs/*.log
{
    rotate 7
    daily
    copytruncate
    missingok
    notifempty
    delaycompress
    compress
    postrotate
    systemctl reload prysm-logs
    endscript
}
EOF

    sudo chmod 644 /etc/logrotate.d/prysm-logs
    sudo chown -R root:root /etc/logrotate.d/prysm-logs
    sudo logrotate /etc/logrotate.conf --debug
  fi
}

# Config Chrony
function config_chrony() {

  sudo vi /etc/chrony/chrony.conf

  /** 
  # Replacing original ubuntu servers by Google servers
  # pool ntp.ubuntu.com        iburst maxsources 4
  # pool 0.ubuntu.pool.ntp.org iburst maxsources 1
  # pool 1.ubuntu.pool.ntp.org iburst maxsources 1
  # pool 2.ubuntu.pool.ntp.org iburst maxsources 2

  # Add these 4 lines
  server time1.google.com iburst minpoll 4 maxpoll 6 polltarget 16
  server time2.google.com iburst minpoll 4 maxpoll 6 polltarget 16
  server time3.google.com iburst minpoll 4 maxpoll 6 polltarget 16
  server time4.google.com iburst minpoll 4 maxpoll 6 polltarget 16
  
  # Update these 
  #log tracking measurements statistics
  maxupdateskew 100.0
  #maxupdateskew 5.0

  makestep 1 3
  #makestep 0.1 -1

  # rest of the doc ...
  # leapsectz right/UTC
  
  sudo systemctl force-reload chrony

  sudo chronyd -Q
  sudo chronyd -q
  
  # Set local time
  timedatectl set-timezone America/Los_Angeles
}

# Config Ports
function config_ports{
	# SSH
	sudo ufw allow ssh
	
	# Beacon
	sudo ufw allow 13000/tcp
	sudo ufw allow 12000/udp
	sudo ufw allow 4000/tcp
  # http://192.168.x.x:8080/metrics
	sudo ufw allow 8080/tcp

  # Beacon QUIC
  sudo ufw allow 13001/udp

	# Validator
	sudo ufw allow 8081/tcp

	# Grafana (optional)
	sudo ufw allow 3000:3100/tcp

	# Geth
	sudo ufw allow 8545/tcp
  sudo ufw allow 8551/tcp
  # http://192.168.x.x:6060/debug/metrics/prometheus
	sudo ufw allow 6060/tcp
	sudo ufw allow 30303/tcp
	sudo ufw allow 30303/udp

	# Prometheus (optional)
	sudo ufw allow 9090/tcp

	# Prometheus-node-exporter
  # http://192.168.x.x:9100/metrics
	sudo ufw allow 9100/tcp
	
	# Enable
	sudo ufw enable

  # Check ports forwarding tool
  # https://www.yougetsignal.com/tools/open-ports/
  # https://mxtoolbox.com/SuperTool.aspx?action=tcp%3a%7Bnode-IP-address%7D%3a13000&run=toolpage
  # curl --http0.9 localhost:13000
  
  # Check local port
  # sudo lsof -n | grep TCP | grep LISTEN | grep 8545
}

# Config Systemd-Resolved
function config_systemd_resolved() {
  if [ ! -e /etc/systemd/resolved.conf.d/dns_servers.conf ]; then
    sudo mkdir /etc/systemd/resolved.conf.d
    
    sudo cat << EOF | sudo tee /etc/systemd/resolved.conf.d/dns_servers.conf >/dev/null
[Resolve]
DNS=8.8.8.8 1.1.1.1
EOF

    sudo systemctl restart systemd-resolved
    # resolvectl status
    # systemd-resolve --status
    # resolvectl query www.google.com
  fi
}

# Config NO-IP
function config_noip() {
  if [ ! -e /etc/systemd/system/noip2.service ]; then
    sudo cat << EOF | sudo tee /etc/systemd/system/noip2.service >/dev/null
[Unit]
Description=NO-IP2 Daemon
After=network.target auditd.service
Wants=network.target

[Service]
Type=forking
ExecStart=/usr/local/bin/noip2
Restart=always
RestartSec=10
User=$USER

[Install]
WantedBy=multi-user.target
EOF

  fi
}

# Config ddclient
function config_ddclient() {
  if [ -e /etc/ddclient.conf ]; then
    sudo vi /etc/ddclient.conf

    # replace the whole file with ddclient config preset from
    # https://freemyip.com/help?domain=mvuong.freemyip.com&token=5b29...7520

    sudo systemctl restart ddclient.service
    sudo systemctl enable ddclient.service    
  fi
}

# Config Aliases for long commands
function config_aliases() {
  curl -L https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/alias.sh | bash && source ~/.bashrc
}

# Config disable power button
function config_disable_power_button() {
  sudo cat << EOF | sudo tee -a /etc/systemd/logind.conf >/dev/null
HandlePowerKey=ignore
EOF

  sudo systemctl restart systemd-logind.service
}

# Config Discord Notification
function config_discord_notify() {
  curl -L https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/auto_upgrade_migration.sh | bash

  # Edit DISCORD_WEBHOOK_URL in /svr/discord_notify.sh 
}

#-------------------------------------------------------------------------------------------#

install_essential

#-------------------------------------------------------------------------------------------#

# EOF