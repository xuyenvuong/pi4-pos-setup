## <span style="color:red">**NOTE: This guide is NOT YET available for MAINNET until April 12th.**</span>

<span style="color:orange">Note: This guide doesn't cover `Validator Exiting`.</span>

---

# Step I - PREPARATION
_Reference => [Ethdo Github](https://github.com/wealdtech/ethdo/releases)_

* SSH into your `Staking Machine`.

* Create `ethdo_withdrawal` directory
```bash
mkdir ~/ethdo_withdrawal
```

* Download `ethdo` binary
```bash
wget -P /tmp https://github.com/wealdtech/ethdo/releases/download/vX.XX.X/ethdo-X.XX.X-linux-amd64.tar.gz

# Untar to ethdo_withdrawal directory
tar -C ~/ethdo_withdrawal -xvzf /tmp/ethdo-X.XX.X-linux-amd64.tar.gz
```

* Make sure ethdo can connect to your `Beaconchain` on your local `Staking Machine`. Check for `Syncing: true`. Only proceed if it is true. Abort otherwise.

```bash
./ethdo node info
```

* Make `ethdo_withdrawal` your current working dir

```bash
cd ~/ethdo_withdrawal
```

* Create `withdrawal_address.txt` and paste your `withdrawal-address` (aka wallet address) in there. Save & Exit.
```bash
vi withdrawal_address.txt
```
--- 

# Step II - BASIC OPERATION
There are 3 different ways to perform `Withdrawal Process`. It depends on how much risk you want to take.

<span style="color:orange">_To proceed, click your preferred method:_</span>

1.  [Online Process on Staking Machine (<span style="color:red">Unsafe</span>)](#onlineUnsafe)
1.  [Offline Process on Staking Machine (<span style="color:red">Unsafe</span>)](#offlineUnsafe)
1.  [Offline Process on Virtual Machine (<span style="color:green">Safe</span>)](#offlineSafe)

---

<div id="onlineUnsafe"></div>

## 1. Online Process on Staking Machine 
<span style="color:red">WARNING</span>: <span style="color:orange">_This is the quickest method, but it's the most `UNSAFE` method since you won't be able to review the `submitted BLS data` and your machine will log the `mnemonic key` in the history/system-log. Error will be irreversable.</span> <span style="color:red">You've been WARNED!!!_</span>

![Online Method](https://raw.githubusercontent.com/wealdtech/ethdo/master/docs/images/credentials-change-online.png)

### Submit BLS Data with Mnemonic Key to Local Consensus Node

* Run this command after replacing the `--mnemonic` with your validator's `mnemonic key`, and `--withdrawal-address` with your wallet's public address (aka Metamask).
* Any validator which associated with the `mnemonic key` will be subject for BLS changes and be submitted.
* Tripple check your `wallet-address` before execute the command

```bash
./ethdo validator credentials set --mnemonic="abandon abandon abandon … art" --withdrawal-address=0x0123…cdef
```

* Verify data submition by validator's index number (e.g. 379075).
```bash
./ethdo validator credentials get --validator=379075
```

You can visually check on [Beaconchain Web](https://beaconcha.in/) by using your validator's index number.

Congrats! You are DONE.

---

<div id="offlineUnsafe"></div>

## 2. Offline Process on Staking Machine

<span style="color:red">WARNING</span>: <span style="color:orange">_This is an easy method, but it's `UNSAFE` since the `mnemonic key` will be kept in the history/system-log._</span>

![Offline Method](https://raw.githubusercontent.com/wealdtech/ethdo/master/docs/images/credentials-change-offline.png)

### Part 1 - Generate Offline Consensus Nodes Data

* This command will generate `offline-preparation.json` file in the current directory.
```bash
./ethdo validator credentials set --prepare-offline
```

### Part 2 - Generate BLS Data

* Run this command after replacing the `--mnemonic` with your validator's `mnemonic key`, and `--withdrawal-address` with your wallet's public address (aka Metamask). 
* Any validator which associated with the `mnemonic key` will be subject for BLS changes and be submitted.
* Tripple check your `wallet-address` before execute the command

```bash
./ethdo validator credentials set --offline --mnemonic="abandon abandon abandon … art" --withdrawal-address=0x0123…cdef
```

* You should expect a newly generated file `change-operations.json` in the current directory. You can open it to inspect, but DO NOT change anything.

### Part 3 - Submit BLS Data to Local Consensus Node

```bash
./ethdo validator credentials set
```

* Verify data submition by validator's index number (e.g. 379075).
```bash
./ethdo validator credentials get --validator=379075
```

You can visually check on [Beaconchain Web](https://beaconcha.in/)

Congrats! You are DONE.

---

<div id="offlineSafe"></div>

## 3. Offline Process on Virtual Machine (VM)
<span style="color:red">WARNING</span>: <span style="color:orange">_This is the `safest` method, but it's complex. You will spin up a temporary offline `Virtual Machine`, then review the data before submit it to the network. The `Virtual Machine` will be discard for any potential data leak to the network._<span style="color:orange">

![Offline Method](https://raw.githubusercontent.com/wealdtech/ethdo/master/docs/images/credentials-change-offline.png)

### Part 1 - Virtual Machine Installation/Setup
* On your current `Windows Machine`

* Follow this guide to download and setup `Virtual Box 7.0` and `Ubuntu Desktop ISO 22.04 LTS`. Click here to follow the guide => [Open Guide](https://ubuntu.com/tutorials/how-to-run-ubuntu-desktop-on-a-virtual-machine-using-virtualbox#1-overview)

* Or, reference to manual download sites:
  1. Download [VirtualBox 7.0](https://www.virtualbox.org/wiki/Downloads)
  1. Download [Ubuntu Desktop ISO 22.04 LTS](https://ubuntu.com/download/desktop/thank-you?version=22.04.2&architecture=amd64)

### Part 2 - Setup SSH to Ubuntu Virtual Machine

* On your VirtualBox
![VirtualBox](https://lh5.googleusercontent.com/yMQCsjA_n3ldbxGQ10zvqehVr3t-gt6Do9Wb42LH6C--9s1-YLYNLqZEUETaBeGYmNDDIEBpFal34Pot87CmkRp-I-JKg8Cv3A5KNpK-c7D-FOoHS0LHvih3mqMzudDZLk-gHa9qGPlx_8y0zPJFTNasgTKvU328wpsCkNiaVKJLUFoPmIMM263RpYhCUQ)

* Boot up your VM, login, then open a terminal, run:
```bash
# Set firewall to allow SSH port 22
sudo ufw allow ssh

# Enable firewall
sudo ufw enable
```

* To open VirtualBox for SSH connections, we need to change the VirtualBox network settings to allow the SSH connection. Navigate to `VirtualBox settings` -> `Network` and make sure you have the settings `Attached to NAT`.
![VM NAT Settings](https://averagelinuxuser.com/assets/images/posts/2022-05-21-ssh-into-virtualbox/Virtualbox-NAT.jpg)

* Then go to `Advanced` -> `Port Forwarding` and add these settings:
  1. Name: `ssh` (or whatever you like)
  1. Protocol: `TCP`
  1. Host Port: `2222` (or any other port you like)
  1. Guest port: `22`

* The IP fields can be left empty.
![Port Forwarding](https://averagelinuxuser.com/assets/images/posts/2022-05-21-ssh-into-virtualbox/Virtualbox-port-forwarding.jpg)

* Test SSH: You can use PuTTY to connect to VM by using `localhost` and port `2222`. If it works then you are ready for the next part #3.

* _(NOTE: To get your `localhost` IP on Windows, open `cmd`, then enter `ipconfig`, hit `Enter` - Copy `IPv4 Address`)_

### Part 3 - Generate Offline Consensus Nodes Data

* On your `Staking Machine`.

* This command will generate `offline-preparation.json` file in the current directory
```bash
./ethdo validator credentials set --prepare-offline
```

### Part 4 - Copy Working Directory to Virtual Machine

* On your `Staking Machine`. Replace with your `username@XXX.XXX.XXX.XXX` with your username and windows' IP address.
* Copy the whole ethdo_withdrawal directory to offline VM

```bash
scp -r -P 2222 ~/ethdo_withdrawal username@XXX.XXX.XXX.XXX:~/.
```

### Part 5 - Generate BLS Data on Virtual Machine

* On your `Virtual Machine`, turn off `Network Connection`
![Turn Off Network Connection](https://tecadmin.net/wp-content/uploads/2020/09/turn-off-networking-ubuntu-20.-04-770x360.png)

* Open a Terminal
![Open Terminal](https://vegibit.com/wp-content/uploads/2016/07/ubuntu-desktop-terminal.jpg)

* Go to `ethdo_withdrawal` directory
```bash
cd ~/ethdo_withdrawal
```

* Open `withdrawal_address.txt` and copy the `withdrawal-address` (e.g. 0x0123…cdef). Use your mouse to high light, then copy text. Then Exit with `Esc` and type `:q!`.

```bash
# Edit and copy the address data
vi withdrawal_address.txt
```

* Run this command after replacing the `--mnemonic` with your validator's `mnemonic key`, and `--withdrawal-address` with your wallet's public address (aka Metamask). 
* Any validator which associated with the `mnemonic key` will be subject for BLS changes and be submitted.
* Tripple check your `wallet-address` before execute the command

```bash
# Tips: Paste the withdrawal-address instead of re-type. You have to manually type in your mnemonic key to make sure.
./ethdo validator credentials set --offline --mnemonic="abandon abandon abandon … art" --withdrawal-address=0x0123…cdef
```

* You should expect a newly generated file `change-operations.json` in the current directory. You can open it to inspect, but DO NOT change anything.

* Now turn on `Network Connection`
![Turn On Network Connection](https://tecadmin.net/wp-content/uploads/2020/09/enable-networking-ubuntu-20.-04.png)

### Part 6 - Move BLS Data to Staking Machine

* On your `Staking Machine`. Copy the `change-operations.json` file from VM to the `Staking Machine` ethdo_withdrawal directory.
* Replace with your `username@XXX.XXX.XXX.XXX` with your username and windows' IP address

```bash
scp -r -P 2222 username@XXX.XXX.XXX.XXX:~/ethdo_withdrawal/change-operations.json ~/ethdo_withdrawal
```

* Shutdown your `Virtual Machine` (No longer need it. You can also remove the VM from VirtualBox)       
![Power Off](https://ubuntuhandbook.org/wp-content/uploads/2020/05/bring-out-submenu.png)

### Part 7 - Submit BLS Data to Local Consensus Mainnet Nodes

* On your `Staking Machine`, run this command to submit the data

```bash
./ethdo validator credentials set
```

* Verify data submition by validator's index number (e.g. 379075).
```bash
./ethdo validator credentials get --validator=379075
```

You can visually check on [Beaconchain Web](https://beaconcha.in/)

Congrats! You are DONE.

---