#!/bin/bash
# setup.sh - A script to quickly setup ETH2.0 Prysm node
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
function uninstall_package() {
  local dpkg_name=$1

  if [ $(dpkg-query -W -f='${Status}' $dpkg_name 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    echo "Uninstalling: $dpkg_name"
    sudo apt purge -y $dpkg_name
  fi
}

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
  install_prometheus
  
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

  # Configs
  systemd_beacon
  systemd_validator
  systemd_clientstats
  systemd_eth2_client_metrics_exporter
  systemd_geth
  systemd_cryptowatch  
  config_prometheus
  config_grafana
  config_logrotate
  config_chrony
  config_ports
  
  # Optional configs
  config_noip
}

# Install Docker
# function install_docker() {
  # if [ ! -e /usr/bin/docker ]; then
    # sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    # curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    # # arch = amd64|arm64|armhf
    # sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	
    # sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  
    # sudo groupadd docker
    # sudo usermod -aG docker $USER
    # newgrp docker
  
    # sudo systemctl enable docker
  # fi
# }

# Install Prometheus
function install_prometheus() {
  if [ $(dpkg-query -W -f='${Status}' prometheus 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Installing: Prometheus"
    sudo useradd -m prometheus
    sudo chown -R prometheus:prometheus /home/prometheus/
    install_package prometheus
    install_package prometheus-node-exporter
    
    # NOTE prometheus-node-exporter: Bug found with awk . Manual remove a backslash on line 13 of this file
    # /usr/share/prometheus-node-exporter-collectors/apt.sh - Should look like this after.
    # | awk '{ gsub(/\\\\/, "\\\\", $2); gsub(/"/, "\\\"", $2);
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
}

# Install Eth2 Client Metrics Exporter
function install_eth2_client_metrics_exporter() {
  if [ ! -e /usr/local/bin/eth2-client-metrics-exporter ]; then
    echo "Installing: Eth2 Client Metrics Exporter"    
    curl -s https://api.github.com/repos/gobitfly/eth2-client-metrics-exporter/releases/latest | grep "eth2-client-metrics-exporter-linux-$(dpkg --print-architecture)" | cut -d : -f 2,3 |  tr -d \" | wget -qi - -O /tmp/eth2-client-metrics-exporter
    chmod +x /tmp/eth2-client-metrics-exporter
    sudo mv /tmp/eth2-client-metrics-exporter /usr/local/bin
  fi 
}

# Install GETH
function install_geth() {  
  if [ ! -e /usr/local/bin/geth ]; then
    # Download latest GETH info
    TAGS_URL=https://api.github.com/repos/ethereum/go-ethereum/tags
    geth_latest_version=$(wget -O - -o /dev/null $TAGS_URL | jq '.[0].name' | tr -d \" | cut -c 2-)
    
    arch=$(dpkg --print-architecture)
    sha=$(wget -O - -o /dev/null $TAGS_URL | jq '.[0].commit.sha' | cut -c 2-9)
    download_version=$arch-$geth_latest_version-$sha
    
    # Download latest tar ball and move to bin folder
    wget -P /tmp https://gethstore.blob.core.windows.net/builds/geth-linux-$download_version.tar.gz
    tar -C /tmp -xvf /tmp/geth-linux-$download_version.tar.gz
    sudo cp /tmp/geth-linux-$download_version/geth /usr/local/bin
  fi
}

function install_auto_upgrade() {
  if [ ! -e $HOME/auto_upgrade.sh ]; then
    wget https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/auto_upgrade.sh && chmod +x auto_upgrade.sh
  fi
}

# Install Cryptowatch
function install_cryptowatch() {
  if [ ! -e /usr/local/bin/cryptowat_exporter ]; then
    wget -P /tmp https://github.com/nbarrientos/cryptowat_exporter/archive/e4bcf6e16dd2e04c4edc699e795d9450dee486ab.zip
    unzip /tmp/e4bcf6e16dd2e04c4edc699e795d9450dee486ab.zip -d /tmp
    cd /tmp/cryptowat_exporter-e4bcf6e16dd2e04c4edc699e795d9450dee486ab
    go build
    cd
    sudo cp /tmp/cryptowat_exporter-e4bcf6e16dd2e04c4edc699e795d9450dee486ab/cryptowat_exporter /usr/local/bin
  fi
}

# Install Prysm
function install_prysm() {
  if [ ! -e $HOME/prysm/prysm.sh ]; then
    curl https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh --output $HOME/prysm/prysm.sh && chmod +x $HOME/prysm/prysm.sh
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
    wget -P $HOME https://github.com/ethereum/staking-deposit-cli/releases/download/v2.0.0/staking_deposit-cli-e2a7c94-linux-amd64.tar.gz    
    tar -C $HOME -xvf /tmp/staking_deposit-cli-e2a7c94-linux-amd64.tar.gz
  fi
  
  #-----------------------------------------------------------------#
  # To run:
  # > cd eth2deposit-cli-256ea21-linux-amd64
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
    wget -P /tmp https://www.noip.com/client/linux/noip-duc-linux.tar.gz
    tar -C /tmp -xvf /tmp/noip-duc-linux.tar.gz
    cd /tmp/noip-2.1.9-1/
    make install

    sudo cp noip2 /usr/local/bin
    /usr/local/bin/noip2 -C -c /tmp/no-ip2.conf
    sudo mv /tmp/no-ip2.conf /usr/local/etc/no-ip2.conf



  fi
}

#-------------------------------------------------------------------------------------------#
# Upgrade all
# function upgrade_all() {
  # echo "Upgrading...."
  
  # # Update & Upgrade to latest
  # sudo apt-get update && sudo apt-get upgrade
  
  # # Pull latest pi4-pos-setup.git repo
  # if [ ! -d $HOME/pos-setup ]; then
    # git clone https://github.com/xuyenvuong/pi4-pos-setup.git $HOME/pos-setup
  # else
    # cd $HOME/pos-setup
    # git pull origin master
    # cd $HOME
  # fi  
# }

#-------------------------------------------------------------------------------------------#
# Initialize pos setup: important files/directories in order to run the PoS node
function build_pos() {   
  # Define setup directories
  mkdir -p $HOME/{.eth2,.eth2validators,.ethereum,.password,logs,prysm,prysm/configs}
  sudo mkdir -p /etc/ethereum
  sudo mkdir -p /home/prometheus/node-exporter
  
  # Create files
  touch $HOME/.password/password.txt
  touch $HOME/logs/{beacon,validator,slasher}.log
}

#-------------------------------------------------------------------------------------------#
# Run backup for all
function backup_all() {
  echo "Backing up...."
}

#-------------------------------------------------------------------------------------------#
# Verify setup 
function verify() {
  echo "Verifying...."
}

#-------------------------------------------------------------------------------------------#
# Display help
function help() {
  echo "Help..."
}


#-------------------------------------------------------------------------------------------#
# Config Files
#-------------------------------------------------------------------------------------------#

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
ExecStart=$HOME/prysm/prysm.sh \$ARGS
Restart=always
RestartSec=3
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

http-web3provider: "http://localhost:8545"
fallback-web3provider: 
- http://192.168.0.XXX:8545
- https://mainnet.infura.io/v3/INFURA_API_KEY
- https://eth-mainnet.alchemyapi.io/v2/ALCHEMY_API_KEY

attest-timely: true

# Sync faster (default 64)
block-batch-limit: 512
head-sync: true

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

# Running slasher
slasher: true
enable-external-slashing-protection: true
disable-broadcast-slashing: true
EOF
  fi
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
RestartSec=3
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

enable-slashing-protection-pruning: true
enable-doppelganger: true

monitoring-port: 8081
monitoring-host: 0.0.0.0

# Mainnet
graffiti: "poapaa2VsI8722DeHPPwjXbJooGadtMA"
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
RestartSec=3
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
RestartSec=3
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
RestartSec=3
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
 --http.port 8545 
 --http.addr 0.0.0.0 
 --syncmode snap 
 --cache 1024 
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

  # Prune geth with tmux
  # /usr/local/bin/geth snapshot prune-state --datadir $HOME/.ethereum  
}  
  
# Systemd Cryptowatch Slasher
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
RestartSec=3
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
function config_prometheus() {
  if [ ! -e /etc/default/prometheus ]; then
    sudo cat << EOF | sudo tee /etc/default/prometheus >/dev/null
ARGS="
 --web.enable-lifecycle
 --storage.tsdb.retention.time=31d
 --storage.tsdb.path=/home/prometheus/metrics2/
"
EOF
  fi
  
  if [ ! -e /etc/default/prometheus-node-exporter ]; then
    sudo cat << EOF | sudo tee /etc/default/prometheus-node-exporter >/dev/null
ARGS="
 --collector.textfile.directory=/home/prometheus/node-exporter
"
EOF
    mkdir -p /home/prometheus/node-exporter
  fi
  
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

	# Slasher
	sudo ufw allow 8082/tcp
	sudo ufw allow 5000/tcp

	# Grafana
	sudo ufw allow 3000:3100/tcp

	# Geth
	sudo ufw allow 8545/tcp
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
  # https://mxtoolbox.com/SuperTool.aspx?action=tcp%3a%7Bnode-IP-address%7D%3a13000&run=toolpage
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
RestartSec=3
User=$USER

[Install]
WantedBy=multi-user.target
EOF

  fi
}

#-------------------------------------------------------------------------------------------#
case $1 in
  -i|--install)    
    install_essential 
	;;  
  -b|--build)
    build_pos
	;;  
  -s|--save)
    backup_all
	;;  
  -h|--help)
    help
	;;
  *)
    echo "Task '$1' is not found!"
    echo "Please use 'setup.sh help' for more info."
    exit 1
    ;;
esac  