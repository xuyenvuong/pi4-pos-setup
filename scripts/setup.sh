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

# Uninstall package
# function uninstall_package() {
#   local dpkg_name=$1

#   if [ $(dpkg-query -W -f='${Status}' $dpkg_name 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
#     echo "Uninstalling: $dpkg_name"
#     sudo apt purge -y $dpkg_name
#   fi
# }

#-------------------------------------------------------------------------------------------#

PRYSM_SH_URL=https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh

DEPOSIT_CLI_RELEASES_LATEST=https://api.github.com/repos/ethereum/staking-deposit-cli/releases/latest

ETH2_CLIENT_METRICS_EXPORTER_RELEASES_LATEST=https://api.github.com/repos/gobitfly/eth2-client-metrics-exporter/releases/latest

GETH_TAGS_URL=https://api.github.com/repos/ethereum/go-ethereum/tags

AUTO_UPGRADE_URL=https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/auto_upgrade_migration.sh

NOIP_URL=https://www.noip.com/client/linux/noip-duc-linux.tar.gz

ARCH=$(dpkg --print-architecture)

#-------------------------------------------------------------------------------------------#
# Main function to install all necessary package to support the node
function install_essential() {
  # Update & Upgrade to latest
  sudo apt-get update && sudo apt-get upgrade
  sudo apt-get dist-upgrade
  sudo apt-get autoremove

  # Docker
  # install_docker
  
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
  install_package python3-dev
  install_package chrony
  install_package jq
  install_package tmux
  install_package ccze
  install_package net-tools
  
  # Prometheus
  #install_prometheus
  install_prometheus_latest
  install_prometheus_node_exporter
  
  # Golang
  install_package golang
  
  # Python
  # install_python
  
  # Grafana
  install_grafana
  
  # Install Eth2 Client Metrics Exporter
  install_eth2_client_metrics_exporter
  
  # GETH
  install_geth
  
  # Auto Upgrade to the latest version scripts
  install_auto_upgrade
  
  # Cryptowatch
  install_cryptowatch
  
  # Prysm
  install_prysm

  # Docker-Compose
  # install_docker_compose
  
  # Validator key generator
  install_validator_key_generator
  
  # NO-IP (optional installation)
  install_noip

  # ddclient (optional installation)
  install_ddclient

  # Google Auth (optional)
  install_google_authenticator

  # Yubikey (optional)  
  install_yubikey

  # Configs
  config_auth_jwt
  systemd_beacon
  systemd_validator
  systemd_clientstats
  systemd_eth2_client_metrics_exporter
  systemd_geth
  systemd_cryptowatch  
  #config_prometheus
  config_prometheus_latest  
  config_grafana
  config_logrotate
  config_chrony
  config_ports
  config_systemd_resolved
  
  # Optional configs
  config_noip
  config_ddclient
  config_aliases
  config_disable_power_button
  config_ssh_yubikey_auth
}

# Install Docker
# function install_docker() {
  # if [ ! -e /usr/bin/docker ]; then
    # sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    # curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    # # arch = amd64|arm64|armhf
    # sudo add-apt-repository "deb [$ARCH] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	
    # sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  
    # sudo groupadd docker
    # sudo usermod -aG docker $USER
    # newgrp docker
  
    # sudo systemctl enable docker
  # fi
# }

# Install Prometheus
# function install_prometheus() {
#   if [ $(dpkg-query -W -f='${Status}' prometheus 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
#     echo "Installing: Prometheus"
#     sudo groupadd --system prometheus
#     #sudo useradd -m prometheus
#     sudo useradd -s /sbin/nologin --system -g prometheus prometheus
#     #sudo chown -R prometheus:prometheus /home/prometheus/
#     install_package prometheus
#     install_package prometheus-node-exporter
    
#     # NOTE prometheus-node-exporter: Bug found with awk . Manual remove a backslash on line 13 of this file
#     # /usr/share/prometheus-node-exporter-collectors/apt.sh - Should look like this after.
#     # | awk '{ gsub(/\\\\/, "\\\\", $2); gsub(/"/, "\\\"", $2);
#   fi
# }

# Install Prometheus latest
function install_prometheus_latest() {
  # https://computingforgeeks.com/install-prometheus-server-on-debian-ubuntu-linux/
  if [ $(dpkg-query -W -f='${Status}' prometheus 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Installing: Prometheus"
    sudo groupadd --system prometheus    
    sudo useradd -s /sbin/nologin --system -g prometheus prometheus
    sudo mkdir /etc/prometheus
    sudo mkdir /var/lib/prometheus

    for i in rules rules.d files_sd; do sudo mkdir -p /etc/prometheus/${i}; done

    # Download latest here: https://prometheus.io/download/
    wget -P /tmp https://github.com/prometheus/prometheus/releases/download/v2.54.0-rc.0/prometheus-2.54.0-rc.0.linux-amd64.tar.gz
    cd /tmp
    tar xvf prometheus*.tar.gz
    cd prometheus*/
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
    echo "Installing: Prometheus Node Exporter"
    
    # Download latest here: https://prometheus.io/download/#node_exporter
    wget -P /tmp https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
    cd /tmp
    tar xvf node_exporter-1.3.1.linux-amd64.tar.gz
    cd cd node_exporter-1.3.1.linux-amd64
    sudo cp node_exporter /usr/local/bin

    sudo useradd --no-create-home --shell /bin/false node_exporter
    sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

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
    sudo systemctl enable node_exporter
    sudo systemctl start node_exporter

    # Note: open port 9100
  fi
}

# Install Python
# function install_python() {
  # if [ $(dpkg-query -W -f='${Status}' python3 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    # echo "Installing: Python"
    # install_package software-properties-common
    # sudo add-apt-repository ppa:deadsnakes/ppa
    # sudo apt-get update
    # install_package python3.8
    # install_package python3-venv
    # install_package python3-pip
  # fi 
# }

# Install Grafana
function install_grafana() {
  if [ $(dpkg-query -W -f='${Status}' grafana-enterprise 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Installing: Grafana"
    install_package apt-transport-https
    install_package software-properties-common
    wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
    echo "deb https://packages.grafana.com/enterprise/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
    sudo apt-get update
    install_package grafana-enterprise
  fi

  sudo openssl genrsa -out /etc/grafana/grafana.key 2048
  $ sudo openssl req -new -key /etc/grafana/grafana.key -out /etc/grafana/grafana.csr
  
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
    echo "Installing: Eth2 Client Metrics Exporter"    
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

function install_auto_upgrade() {
  if [ ! -e $HOME/auto_upgrade.sh ]; then
    curl -L $AUTO_UPGRADE_URL | bash
  fi
}

# Install Cryptowatch
function install_cryptowatch() {
  if [ ! -e /usr/local/bin/cryptowat_exporter ]; then
    wget -P /tmp https://github.com/nbarrientos/cryptowat_exporter/archive/e4bcf6e16dd2e04c4edc699e795d9450dee486ab.zip
    unzip /tmp/e4bcf6e16dd2e04c4edc699e795d9450dee486ab.zip -d /tmp
    cd /tmp/cryptowat_exporter-e4bcf6e16dd2e04c4edc699e795d9450dee486ab
    go build
    cd ~
    sudo cp /tmp/cryptowat_exporter-e4bcf6e16dd2e04c4edc699e795d9450dee486ab/cryptowat_exporter /usr/local/bin
  fi
}

# Install Prysm
function install_prysm() {
  if [ ! -e $HOME/prysm/prysm.sh ]; then
    curl $PRYSM_SH_URL --output $HOME/prysm/prysm.sh && chmod +x $HOME/prysm/prysm.sh
  fi
}

# Install Docker-Compose
# function install_docker_compose() {
  # if [ ! -e /usr/local/bin/docker-compose ]; then
  
    # sudo pip3 install cryptography
    # sudo pip3 install docker-compose
  # fi  
# }

# Install Validator Key Generator
function install_validator_key_generator() {
  if [ ! -e $HOME/staking_deposit-cli-e2a7c94-linux-amd64/deposit ]; then    
    deposit_cli_filename=$(wget -O - -o /dev/null $DEPOSIT_CLI_RELEASES_LATEST | jq '.assets[].name' | grep linux-$ARCH | tr -d \")
    browser_download_url=$(wget -O - -o /dev/null $DEPOSIT_CLI_RELEASES_LATEST | jq '.assets[].browser_download_url' | grep linux-$ARCH | tr -d \")

    wget -P /tmp $browser_download_url
    tar -C $HOME -xzvf /tmp/$deposit_cli_filename
  fi

  # Download via Github GUI
  # https://github.com/ethereum/staking-deposit-cli/releases
  
  #-----------------------------------------------------------------#
  # To run:
  # > cd staking_deposit-cli-d7b5304-linux-amd64
  # > ./deposit new-mnemonic --num_validators 1 --chain mainnet
  # At prompt, enter the seeds pharse, then 
  # At prompt follow by enter ACCOUNT PASSWORD, Save it to Bitwarden
  
  #-----------------------------------------------------------------#
  # To Import Keys
  # > prysm/prysm.sh validator accounts import --keys-dir=$HOME/eth2.0-deposit-cli/validator_keys --mainnet --accept-terms-of-use
  # Input wallet path
	# Prompt> $HOME/.eth2validators/prysm-wallet-v2
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
  # > prysm/prysm.sh validator accounts import --wallet-dir=$HOME/.eth2validators/prysm-wallet-v2 --keys-dir=$HOME/validator_keys_mainnet.xx_xx_keys --mainnet --accept-terms-of-use
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
# Initialize pos setup: important files/directories in order to run the PoS node
function build_pos() {   
  # Define setup directories
  mkdir -p $HOME/{.eth2,.eth2validators,.ethereum,.password,logs,prysm,prysm/configs}
  sudo mkdir -p /etc/ethereum
  sudo mkdir -p /home/prometheus/node-exporter
  
  # Create files
  touch $HOME/.password/password.txt
  touch $HOME/logs/{beacon,validator}.log
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
function systemd_beacon() {
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
  if [ ! -e $HOME/prysm/configs/beacon.yaml ]; then
    sudo cat << EOF | tee $HOME/prysm/configs/beacon.yaml >/dev/null
datadir: "$HOME/.eth2"
log-file: "$HOME/logs/beacon.log"

# Mainnet Contract
deposit-contract: 0x00000000219ab540356cbb839cbe05303d7705fa
contract-deployment-block: 11052984

verbosity: info

execution-endpoint: "http://localhost:8551"

jwt-secret: /etc/ethereum/jwt.hex

attest-timely: true

# Sync faster (default 64)
block-batch-limit: 128

#p2p-host-ip: $(curl -s v4.ident.me)
p2p-host-dns: "maxvuong.tplinkdns.com"

p2p-tcp-port: 13000
p2p-udp-port: 12000

p2p-max-peers: 100
min-sync-peers: 3

rpc-port: 4000
rpc-host: 0.0.0.0

monitoring-port: 8080
monitoring-host: 0.0.0.0

update-head-timely: true

suggested-fee-recipient: 0xYOUR_WALLET_ADDRESS

# Mev Boost
http-mev-relay: http://localhost:18550

# Faster sync
checkpoint-sync-url: https://sync-mainnet.beaconcha.in
genesis-beacon-api-url: https://sync-mainnet.beaconcha.in

# **** CHECK THIS FLAG WHEN RESYNC ****
# save-full-execution-payloads: true

# BAD - corrupted db
#enable-experimental-state: true

# BAD - corrupted db
#enable-eip-4881: true

rpc-max-page-size: 200000
grpc-max-msg-size: 268435456

# 12s is the upper bound
engine-endpoint-timeout-seconds: 10

aggregate-first-interval: 7500ms
aggregate-second-interval: 9800ms
aggregate-third-interval: 11900ms

#aggregate-parallel: true

blob-save-fsync: true
enable-minimal-slashing-protection: true
save-invalid-block-temp: true

# Optional
local-block-value-boost: 5
#backfill-oldest-slot: 0

EOF
  fi

  # Check beacon sync status
  # curl http://localhost:3500/eth/v1/node/syncing
}

# Systemd Validator Service
function systemd_validator() {
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
  if [ ! -e $HOME/prysm/configs/validator.yaml ]; then
    sudo cat << EOF | tee $HOME/prysm/configs/validator.yaml >/dev/null
datadir: "$HOME/.eth2"
log-file: "$HOME/logs/validator.log"

verbosity: info

wallet-dir: "$HOME/.eth2validators/prysm-wallet-v2"
wallet-password-file: "$HOME/.password/password.txt"

beacon-rpc-provider: localhost:4000,host1:port,host2:port

attest-timely: true

enable-slashing-protection-history-pruning: true
enable-external-slashing-protection: true
enable-doppelganger: true

monitoring-port: 8081
monitoring-host: 0.0.0.0

# Mainnet
graffiti: "poapaa2VsI8722DeHPPwjXbJooGadtMA"

suggested-fee-recipient: ______0xYOUR_WALLET_ADDRESS______
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

# Systemd Eth2 Client Metrics Exporter Service
function systemd_eth2_client_metrics_exporter() {
  if [ ! -e /etc/systemd/system/prysm-clientstats.service ]; then
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
  if [ ! -e /etc/ethereum/prysm-clientstats.conf ]; then
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
function systemd_geth() {
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
 --http.api eth,net,engine,admin
 --http.port 8545 
 --http.addr 0.0.0.0 
 --authrpc.jwtsecret /etc/ethereum/jwt.hex
 --authrpc.addr 0.0.0.0
 --authrpc.port 8551
 --authrpc.vhosts * 
 --syncmode snap 
 --db.engine pebble
 --state.scheme path
 --datadir $HOME/.ethereum
 --metrics 
 --metrics.expensive 
 --pprof 
 --pprof.port 6060 
 --pprof.addr 0.0.0.0 
 --maxpeers 100 
 --identity Maximus 
 --ethstats Maximus:a38e1e50b1b82fa@ethstats.net
"
EOF
  fi

  # Use ancient db dir with this flag:  
  #--datadir.ancient /mnt/ssd2/ethereum/geth/chaindata/ancient
  
  # Prune geth with tmux
  # /usr/local/bin/geth snapshot prune-state --datadir $HOME/.ethereum  

  # Check Geth syncing status
  # /usr/local/bin/geth attach http://localhost:8545
  # > eth.syncing
}  
  
# Systemd Cryptowatch
function systemd_cryptowatch() {
  if [ ! -e /etc/systemd/system/cryptowatch.service ]; then
    sudo cat << EOF | sudo tee /etc/systemd/system/cryptowatch.service >/dev/null
[Unit]
Description=Cryptowatch Daemon
After=network.target
Requires=prometheus.service

[Service]
EnvironmentFile=/etc/ethereum/cryptowatch.conf
ExecStart=/usr/local/bin/cryptowat_exporter \$ARGS
Restart=always
RestartSec=10
User=$USER

[Install]
WantedBy=multi-user.target
EOF
  fi

  # EnvironmentFile
  if [ ! -e /etc/ethereum/cryptowatch.conf ]; then
    sudo cat << EOF | sudo tee /etc/ethereum/cryptowatch.conf >/dev/null
ARGS="
 --cryptowat.pairs=etheur,ethusd,ethgbp,ethcad,ethchf,ethjpy,ethbtc
 --cryptowat.exchanges=kraken
"
EOF
  fi   
}  

# Config Prometheus
# function config_prometheus() {
#   if [ ! -e /etc/default/prometheus ]; then
#     sudo cat << EOF | sudo tee /etc/default/prometheus >/dev/null
# ARGS="
#  --web.enable-lifecycle
#  --storage.tsdb.retention.time=31d
#  --storage.tsdb.path=/var/lib/prometheus
# "
# EOF
#   fi
  
#   if [ ! -e /etc/default/prometheus-node-exporter ]; then
#     sudo cat << EOF | sudo tee /etc/default/prometheus-node-exporter >/dev/null
# ARGS="
#  --collector.textfile.directory=/var/lib/prometheus/node-exporter
# "
# EOF
#     #mkdir -p /home/prometheus/node-exporter
#   fi
  
#   # Concat to existing file
#   if [ ! -e /etc/prometheus/prometheus.yml ]; then
#     sudo cat << EOF | sudo tee -a /etc/prometheus/prometheus.yml >/dev/null

#   - job_name: geth
#     scrape_interval: 15s
#     scrape_timeout: 10s
#     metrics_path: /debug/metrics/prometheus
#     scheme: http
#     static_configs:
#       - targets: ['localhost:6060']

#   - job_name: 'validator'
#     static_configs:
#       - targets: ['localhost:8081']

#   - job_name: 'beacon node'
#     static_configs:
#       - targets: ['localhost:8080']

#   - job_name: 'cryptowat'
#     static_configs:
#       - targets: ['localhost:9745']
# EOF
#   fi 
# }

# Config Prometheus lastest
function config_prometheus_latest() {
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

  - job_name: 'cryptowat'
    static_configs:
      - targets: ['localhost:9745']
EOF
  fi 
}

# Config Grafana DB
function config_grafana() {
  # Geth1.0 - Single node
  # https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/sources/Geth_ETH_1.0.json
  # Geth2.0 - Multiple nodes
  # https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/sources/Geth1.0.json
  # Ethereum on AMD node monitor
  # https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/sources/EthereumOnArmAmdNode.json
  # Eth Staking Dashboard
  # https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/sources/EthStakingDashboard.json  
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
  */

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
	sudo ufw allow 13000:13100/tcp
	sudo ufw allow 12000:12100/udp
	sudo ufw allow 4000/tcp
	sudo ufw allow 8080/tcp

	# Validator
	sudo ufw allow 8081/tcp

	# Grafana
	sudo ufw allow 3000:3100/tcp

	# Geth
	sudo ufw allow 8545/tcp
  sudo ufw allow 8551/tcp
	sudo ufw allow 6060/tcp
	sudo ufw allow 30303:30309/tcp
	sudo ufw allow 30303:30309/udp

	# Prometheus
	sudo ufw allow 9090/tcp

	# Prometheus-node-exporter
	sudo ufw allow 9100/tcp

	# Cryptowatch
	sudo ufw allow 9745/tcp

	# Prysm UI
	sudo ufw allow 7500/tcp
	
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
  curl -L https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/alias.sh | bash && source $HOME/.bashrc
}

# Config disable power button
function config_disable_power_button() {
  sudo cat << EOF | sudo tee -a /etc/systemd/logind.conf >/dev/null
HandlePowerKey=ignore
EOF

  sudo systemctl restart systemd-logind.service
}

#-------------------------------------------------------------------------------------------#

install_essential

#-------------------------------------------------------------------------------------------#

# EOF