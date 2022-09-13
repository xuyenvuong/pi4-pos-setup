
# Merge Readiness Update (Its required to upgrade by today)

Ethereum has released new upgrade that would require you to take immediate action today. If you fail to do it by today, you node may go down since incompatibility between the Consensus Layer and Execution Layer. (I can jump online to help you just incase)

## Step 1:
First, go to https://ethstats.net/, and make sure your GETH node is at version `v1.10.22` - If you are, then go to **Step 2**
_(Note: The upgrade won't work if you are at lower version)_

How to upgrade GETH to `v1.10.22`, run these commands:
> `wget -P /tmp https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.22-2de49b04.tar.gz`
> 
> `tar -xvzf /tmp/geth-linux-amd64-1.10.22-2de49b04.tar.gz -C /tmp`
> 
> `sudo systemctl stop geth.service`
> 
> `sudo mv /usr/local/bin/geth /usr/local/bin/geth.20220822`
> 
> `sudo cp /tmp/geth-linux-amd64-1.10.22-2de49b04/geth /usr/local/bin`
> 
> `sudo systemctl start geth.service`

## Step 2: Generate JWT (Java Web Token), run these commands:
> `openssl rand -hex 32 | tr -d "\n" | sudo tee /etc/ethereum/jwt.hex >/dev/null`

_(Note: If you are running Beacon and Geth on 2 different machines, then you will need to copy the `/etc/ethereum/jwt.hex` file to both machines. Also, open **port 8551** on the GETH node by running this command `sudo ufw allow 8551/tcp`)_

## Step 3: Re-configure GETH, edit this file:
> `sudo vi /etc/ethereum/geth.conf`

Then add these parameters:
>  `--authrpc.jwtsecret /etc/ethereum/jwt.hex`
>  `--authrpc.addr 0.0.0.0`
>  `--authrpc.port 8551`
>  `--authrpc.vhosts localhost`

Save and exit. 

Then, 

> `sudo systemctl restart geth.service`

Check log - if you encounter any error, let me know asap

> `journalctl -f -u geth.service`

## Step 4: Re-configure Prysm, edit this file:

> `vi prysm/configs/beacon.yaml`

Then add these parameters:

> `jwt-secret: /etc/ethereum/jwt.hex`

> `grpc-max-msg-size: 65568081`

> `enable-only-blinded-beacon-blocks: true`

Then remove these parameters:

> `fallback-web3provider` 

> `- https://mainnet.infura.io/v3/INFURA_API_KEY`

> `- https://eth-mainnet.alchemyapi.io/v2/ALCHEMY_API_KEY`

> `enable-peer-scorer`

And Edit this parameter, to port 8551 (instead of the legacy 8545)

> `http-web3provider: "http://localhost:8551"`

(Don't foreget to setup the `suggested-fee-recipient: 0xYOUR_WALLET_ADDRESS` if you haven't)

Save and exit.

Then, restart Beacon and Validator

> `sudo systemctl restart prysm-beacon.service`

> `sudo systemctl restart prysm-validator.service`

Check logs - if you encounter any error, let me know asap

> `journalctl -f -u prysm-beacon.service`

> `journalctl -f -u prysm-validator.service`

Done.