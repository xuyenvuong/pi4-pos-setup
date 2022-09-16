# MEV BOOST Setup Readiness

You will need to install MEV Boost asap to take advantage of the higher earning. Best is to set it up before the Merge on September 15th.

Please follow step by step with below instructions:

---


## Install Go 1.19+
```Bash
$ cd ~
$ sudo apt -y update
$ sudo apt -y install build-essential

$ wget -P /tmp https://go.dev/dl/go1.19.linux-amd64.tar.gz

$ sudo rm -rf /usr/local/go
$ sudo tar -C /usr/local -xzf /tmp/go1.19.linux-amd64.tar.gz
$ export PATH=$PATH:/usr/local/go/bin
$ echo 'PATH="$PATH:/usr/local/go/bin"' >> ~/.profile

$ rm /tmp/go1.19.linux-amd64.tar.gz
```

---


## Install MEV-BOOST
```Bash
$ /usr/local/go/bin/go install github.com/flashbots/mev-boost@latest
$ sudo cp ~/go/bin/mev-boost /usr/local/bin
```

---


## Setup MEV-BOOST Daemon
```Bash
$ sudo cat << EOF | sudo tee /etc/systemd/system/mevboost.service >/dev/null
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
```

---


## Setup MEV-BOOST Mainnet Config
```Bash
$ sudo cat << EOF | sudo tee /etc/ethereum/mevboost.conf >/dev/null
ARGS="
 -mainnet
 -relay-check
 -relays https://0xac6e77dfe25ecd6110b8e780608cce0dab71fdd5ebea22a16c0205200f2f8e2e3ad3b71d3499c54ad14d6c21b41a37ae@boost-relay.flashbots.net,https://0x8b5d2e73e2a3a55c6c87b8b6eb92e0149a125c852751db1422fa951e42a09b82c142c3ea98d0d9930b056a3bc9896b8f@bloxroute.max-profit.blxrbdn.com,https://0xad0a8bb54565c2211cee576363f3a347089d2f07cf72679d16911d740262694cadb62d7fd7483f27afd714ca0f1b9118@bloxroute.ethical.blxrbdn.com,https://0x9000009807ed12c1f08bf4e81c6da3ba8e3fc3d953898ce0102433094e5f22f21102ec057841fcb81978ed1ea0fa8246@builder-relay-mainnet.blocknative.com
"
EOF
```

---


## Setup Aliases for MEV-BOOST
```Bash
$ sudo cat << EOF | sudo tee -a $HOME/.bashrc >/dev/null
alias mevboost-log='journalctl -f -u mevboost.service -n 200 | ccze -A'
alias mevboost-start='sudo systemctl start mevboost.service'
alias mevboost-stop='sudo systemctl stop mevboost.service'
alias mevboost-restart='sudo systemctl restart mevboost.service'
alias mevboost-enable='sudo systemctl enable mevboost.service'
EOF

$ source ~/.bashrc
```

---


## Enable MEV-BOOST service
```Bash
$ mevboost-start
$ mevboost-enable
$ mevboost-log
```

> _NOTE: If you see `"listening on localhost:18550"` message from the log, you are good to go. Hit `Ctrl+c` to exit the log._

---


## Beacon Config Update
```Bash
$ vi prysm/configs/beacon.yaml
```
Insert this at the end of the file: _`http-mev-relay: http://localhost:18550`_

Then Save and Exit.

```Bash
$ beacon-restart
$ beacon-log
```

> _NOTE: If you see `"Builder has been configured" endpoint="http://localhost:18550"` from the log, you are good to go. Hit `Ctrl+c` to exit the log._


---


## Validator Config Update
```Bash
$ vi prysm/configs/validator.yaml
```
Insert this at the end of the file: _`enable-builder: true`_

Then Save and Exit.

```Bash
$ validator-restart
$ mevboost-log
```

> _NOTE: If you see `"level=info msg="http: POST /eth/v1/builder/validators 200" duration=0.672797662 method=POST module=service path=/eth/v1/builder/validators status=200"` from the log, you are good to go. Hit `Ctrl+c` to exit the log._

***