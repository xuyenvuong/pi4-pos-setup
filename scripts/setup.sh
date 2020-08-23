#!/bin/bash
# setup.sh - A script to quickly setup ETH2.0 Prysm node
# Author: Max Vuong

set -eu

# Install package
function install_package() {
  local dpkg_name=$1

  if [ $(dpkg-query -W -f='${Status}' $dpkg_name 2>/dev/null | grep -c "ok installed") -eq 0 ]
  then
    echo "Installing: $dpkg_name"
    sudo apt install -y $dpkg_name
  fi
}

# Uninstall package
function uninstall_package() {
  local dpkg_name=$1

  if [ $(dpkg-query -W -f='${Status}' $dpkg_name 2>/dev/null | grep -c "ok installed") -eq 1 ]
  then
    echo "Uninstalling: $dpkg_name"
	sudo apt purge -y $dpkg_name
  fi
}
#-------------------------------------------------------------------------------------------#
# Main function to install all necessary package to support the node
function install_essential() {
  # Update & Upgrade to latest
  sudo apt-get update && sudo apt-get upgrade
  
  # Docker
  install_docker

  # Independent packages
  install_package vim
  install_package git-all
  install_package zip
  install_package unzip
  install_package build-essential
  
  # Prometheus
  install_prometheus
  
  # Golang
  install_package golang
  
  # Python
  install_python
  
  # Grafana
  install_grafana
  
  # GETH
  install_geth
  
  # Cryptowatch
  install_cryptowatch
  
  # Prysm
  install_prysm
  
  # Configs
  systemd_beacon
  systemd_validator
  systemd_slasher
  systemd_geth
  systemd_cryptowatch
  systemd_eth2stats
  config_prometheus
  config_grafana
  config_logrotate
}

# Install Docker
function install_docker() {
  if [ $(dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep -c "ok installed") -eq 0 ]
  then
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  
    # TODO: support other options beside arm64
    sudo add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  
    sudo groupadd docker
    sudo usermod -aG docker $USER
    newgrp docker
  
    sudo systemctl enable docker
  fi
}

# Install Prometheus
function install_prometheus() {
  if [ $(dpkg-query -W -f='${Status}' prometheus 2>/dev/null | grep -c "ok installed") -eq 0 ]
  then
    echo "Installing: Prometheus"
	sudo useradd -m prometheus
	sudo chown -R prometheus:prometheus /home/prometheus/
    install_package prometheus
    install_package prometheus-node-exporter
  fi
}

# Install Python
function install_python() {
  if [ $(dpkg-query -W -f='${Status}' python3 2>/dev/null | grep -c "ok installed") -eq 0 ]
  then
    echo "Installing: Python"
	install_package software-properties-common
	sudo add-apt-repository ppa:deadsnakes/ppa
	sudo apt-get update
	install_package python3.8
	install_package python3-venv
	install_package python3-pip
  fi 
}

# Install Grafana
function install_grafana() {
  if [ $(dpkg-query -W -f='${Status}' grafana-enterprise 2>/dev/null | grep -c "ok installed") -eq 0 ]
  then
    echo "Installing: Grafana"
    install_package apt-transport-https
    install_package software-properties-common
	wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
    echo "deb https://packages.grafana.com/enterprise/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
    sudo apt-get update
    install_package grafana-enterprise
  fi 
}

# Install GETH
function install_geth() {  
  if [ ! -e /usr/local/bin/geth ]
  then
    # Installing version 1.9.19
    wget -P /tmp https://gethstore.blob.core.windows.net/builds/geth-linux-arm64-1.9.19-3e064192.tar.gz
    mkdir -p /tmp/geth-linux-arm64-1.9.19-3e064192
    tar -C /tmp/geth-linux-arm64-1.9.19-3e064192 --strip-components 1 -xvf /tmp/geth-linux-arm64-1.9.19-3e064192.tar.gz
    sudo cp -a /tmp/geth-linux-arm64-1.9.19-3e064192/geth /usr/local/bin
  fi
}

# Install Cryptowatch
function install_cryptowatch() {
  if [ ! -e /usr/local/bin/cryptowat_exporter ]
  then
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
  if [ ! -e $HOME/prysm/prysm.sh ]
  then
    curl https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh --output $HOME/prysm/prysm.sh && chmod +x $HOME/prysm/prysm.sh
  fi
}

#-------------------------------------------------------------------------------------------#
# Upgrade all
function upgrade_all() {
  echo "Upgrading...."
  
  # Update & Upgrade to latest
  sudo apt-get update && sudo apt-get upgrade
  
  # Pull latest pi4-pos-setup.git repo
  if [ ! -d $HOME/pos-setup ]
  then
    git clone https://github.com/xuyenvuong/pi4-pos-setup.git $HOME/pos-setup
  else
    cd $HOME/pos-setup
    git pull origin master
    cd $HOME
  fi  
}

#-------------------------------------------------------------------------------------------#
# Initialize pos setup: important files/directories in order to run the PoS node
function build_pos() {   
  # Define setup directories
  mkdir -p $HOME/{.eth2,.eth2stats,.eth2validators,.ethereum,.password,logs,prysm,prysm/configs}
  sudo mkdir -p /etc/ethereum
  sudo mkdir -p /home/prometheus/node-exporter
  
  # Create files
  touch $HOME/.password/password.txt
  touch $HOME/logs/{beacon,validator,slasher}.log
  
  # Clone pi4-pos-setup.git repo
  if [ ! -d $HOME/pos-setup ]
  then
    git clone https://github.com/xuyenvuong/pi4-pos-setup.git $HOME/pos-setup
  fi
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
  if [ ! -e /etc/systemd/system/prysm-beacon.service ]
  then
    sudo cat << EOF > /tmp/prysm-beacon.service
[Unit]
Description=Prysm Beacon Daemon
After=network.target auditd.service
Requires=network.target

[Service]
EnvironmentFile=/etc/ethereum/prysm-beacon.conf
ExecStart=$HOME/prysm/prysm.sh $ARGS
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
Alias=prysm-beacon.service
EOF
    sudo mv /tmp/prysm-beacon.service /etc/systemd/system
  fi
  
  # EnvironmentFile
  if [ ! -e /etc/ethereum/prysm-beacon.conf ]
  then
    sudo cat << EOF > /tmp/prysm-beacon.conf
ARGS="beacon-chain --config-file=$HOME/prysm/configs/beacon.yaml"
EOF
    sudo mv /tmp/prysm-beacon.conf /etc/ethereum
  fi
  
  # YAML
  if [! -e $HOME/prysm/configs/beacon.yaml ]
  then
    sudo cat << EOF > $HOME/prysm/configs/beacon.yaml
datadir: "$HOME/.eth2"
log-file: "$HOME/logs/beacon.log"

# Medalla Testnet Contract
deposit-contract: 0x07b39F4fDE4A38bACe212b546dAc87C58DfE3fDC
contract-deployment-block: 3085928

verbosity: info
http-web3provider: "http://localhost:8545"

p2p-host-ip: $(curl -s v4.ident.me)

p2p-tcp-port: 13000
p2p-max-peers: 30
min-sync-peers: 3

slasher-provider: localhost:5000
EOF
  fi
}

# Systemd Validator Service
function systemd_validator() {
  if [ ! -e /etc/systemd/system/prysm-validator.service ]
  then
    sudo cat << EOF > /tmp/prysm-validator.service
[Unit]
Description=Prysm Validator Daemon
After=network.target auditd.service prysm-beacon.service
Requires=network.target

[Service]
EnvironmentFile=/etc/ethereum/prysm-validator.conf
ExecStart=$HOME/prysm/prysm.sh $ARGS
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
Alias=prysm-validator.service
EOF
    sudo mv /tmp/prysm-validator.service /etc/systemd/system
  fi
  
  # EnvironmentFile
  if [ ! -e /etc/ethereum/prysm-validator.conf ]
  then
    sudo cat << EOF > /tmp/prysm-validator.conf
ARGS="validator --config-file=$HOME/prysm/configs/validator.yaml"
EOF
    sudo mv /tmp/prysm-validator.conf /etc/ethereum
  fi
  
  # YAML
  if [! -e $HOME/prysm/configs/validator.yaml ]
  then
    sudo cat << EOF > $HOME/prysm/configs/validator.yaml
datadir: "$HOME/.eth2"
log-file: "$HOME/logs/validator.log"

verbosity: info

wallet-dir: "$HOME/.eth2validators/prysm-wallet-v2"
passwords-dir: "$HOME/.eth2validators/prysm-wallet-v2-passwords"
wallet-password-file: "$HOME/.password/password.txt"

beacon-rpc-provider: localhost:4000
EOF
  fi
}
  
# Systemd Slasher Service
function systemd_slasher() {
  if [ ! -e /etc/systemd/system/prysm-slasher.service ]
  then
    sudo cat << EOF > /tmp/prysm-slasher.service
[Unit]
Description=Prysm Validator Daemon
After=network.target auditd.service prysm-beacon.service
Requires=network.target

[Service]
EnvironmentFile=/etc/ethereum/prysm-slasher.conf
ExecStart=$HOME/prysm/prysm.sh $ARGS
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
Alias=prysm-slasher.service
EOF
    sudo mv /tmp/prysm-slasher.service /etc/systemd/system
  fi

  # EnvironmentFile
  if [ ! -e /etc/ethereum/prysm-slasher.conf ]
  then
    sudo cat << EOF > /tmp/prysm-slasher.conf
ARGS="slasher --config-file=$HOME/prysm/configs/slasher.yaml"
EOF
    sudo mv /tmp/prysm-slasher.conf /etc/ethereum
  fi
  
  # YAML
  if [! -e $HOME/prysm/configs/slasher.yaml ]
  then
    sudo cat << EOF > $HOME/prysm/configs/slasher.yaml
datadir: "$HOME/.eth2"
log-file: "$HOME/logs/slasher.log"

verbosity: info

beacon-rpc-provider: localhost:4000
EOF
  fi
}
  
# Systemd GETH Service
function systemd_geth() {
  if [ ! -e /etc/systemd/system/geth.service ]
  then
    sudo cat << EOF > /tmp/geth.service
[Unit]
Description=Geth Node Daemon
After=network.target auditd.service
Wants=network.target

[Service]
EnvironmentFile=/etc/ethereum/geth.conf
ExecStart=/usr/local/bin/geth $ARGS
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
Alias=geth.service
EOF
    sudo mv /tmp/geth.service /etc/systemd/system
  fi
  
  # EnvironmentFile
  if [ ! -e /etc/ethereum/geth.conf ]
  then
    sudo cat << EOF > /tmp/geth.conf
ARGS="--goerli --port 30303 --rpcport 8545 --syncmode fast --cache 1024 --datadir $HOME/.ethereum --metrics --metrics.expensive --pprof --maxpeers 100"
EOF
    sudo mv /tmp/geth.conf /etc/ethereum
  fi  
}  
  
# Systemd Cryptowatch Slasher
function systemd_cryptowatch() {
  if [ ! -e /etc/systemd/system/cryptowatch.service ]
  then
    sudo cat << EOF > /tmp/cryptowatch.service
[Unit]
Description=Cryptowatch Daemon
After=network.target
Requires=prometheus.service

[Service]
EnvironmentFile=/etc/ethereum/cryptowatch.conf
ExecStart=/usr/local/bin/cryptowat_exporter $ARGS
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
EOF
    sudo mv /tmp/cryptowatch.service /etc/systemd/system
  fi

  # EnvironmentFile
  if [ ! -e /etc/ethereum/cryptowatch.conf ]
  then
    sudo cat << EOF > /tmp/cryptowatch.conf
ARGS="--cryptowat.pairs=etheur,ethusd,ethgbp,ethcad,ethchf,ethjpy,ethbtc --cryptowat.exchanges=kraken"  
EOF
    sudo mv /tmp/cryptowatch.conf /etc/ethereum
  fi   
}  

# Systemd Eth2stats Service (Docker check)
function systemd_eth2stats() {
  if [ ! -e /etc/systemd/system/prysm-eth2stats.service ]
  then
    sudo cat << EOF > /tmp/prysm-eth2stats.service
[Unit]
Description=Prysm Eth2stats Daemon
After=network.target
Requires=prysm-beacon.service

[Service]
EnvironmentFile=/etc/ethereum/prysm-eth2stats.conf
ExecStart=/usr/bin/docker $ARGS
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
Alias=prysm-eth2stats.service
EOF
    sudo mv /tmp/prysm-eth2stats.service /etc/systemd/system
  fi
  
  # EnvironmentFile
  if [ ! -e /etc/ethereum/prysm-eth2stats.conf ]
  then
    sudo cat << EOF > /tmp/prysm-eth2stats.conf
ARGS="start -i eth2stats-client"  
EOF
    sudo mv /tmp/prysm-eth2stats.conf /etc/ethereum
  fi
}   

# Config Prometheus
function config_prometheus() {
  if [ ! -e /etc/default/prometheus ]
  then
    sudo cat << EOF > /tmp/prometheus
ARGS="--web.enable-lifecycle --storage.tsdb.retention.time=31d --storage.tsdb.path="/home/prometheus/metrics2/""
EOF
    sudo mv /tmp/prometheus /etc/default
  fi
  
  if [ ! -e /etc/default/prometheus-node-exporter ]
  then
    sudo cat << EOF > /tmp/prometheus-node-exporter
ARGS="--collector.textfile.directory="/home/prometheus/node-exporter"
EOF
    sudo mv /tmp/prometheus-node-exporter /etc/default
  fi

  if [ ! -e /etc/prometheus/prometheus.yml ]
  then
    sudo cat << EOF > /tmp/prometheus.yml
# Sample config for Prometheus.

global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
      monitor: 'example'

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets: ['localhost:9093']

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s
    scrape_timeout: 5s

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ['localhost:9090']

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

  - job_name: 'cryptowat'
    static_configs:
      - targets: ['localhost:9745']
EOF
    sudo mv /tmp/prometheus.yml /etc/prometheus
  fi 
}

# Config Grafana DB
function config_grafana() {
  if [ ! -e /var/lib/grafana/grafana.db ]
  then
    wget -P /tmp https://github.com/xuyenvuong/pi4-pos-setup/raw/master/sources/grafana.db
    sudo cp -a /tmp/grafana.db /var/lib/grafana/grafana.db
    sudo chown grafana:grafana /var/lib/grafana/grafana.db
  fi  
}

# Config Logrotate
function config_logrotate() {
  if [ ! -e /etc/logrotate.d/prysm-logs ]
  then
    sudo cat << EOF > /tmp/prysm-logs
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
    sudo mv /tmp/prysm-logs /etc/logrotate.d
	sudo logrotate /etc/logrotate.conf --debug
  fi
}


#-------------------------------------------------------------------------------------------#
case $1 in
  -i|--install)    
    install_essential 
	;;  
  -u|--upgrade)
    upgrade_all
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