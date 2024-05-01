
# Rsync with RSA
ssh-keygen
rsync -avzh ubuntu@192.168.0.185:~/.eth2/beaconchaindata /mnt/ssd2/eth2tmpname/beaconchaindata --rsh="ssh -i ~/.ssh/id_rsa"

# USB WIFI Dongo RTL8814AU driver
sudo apt install dkms git
mkdir -p /tmp/USB_WIFI_Driver_src
cd /tmp/USB_WIFI_Driver_src
git clone https://github.com/morrownr/8814au.git
cd 8814au
sudo ./install-driver.sh
sudo shutdown -r now

# Setup WIFI
sudo apt install net-tools
ifconfig -a
sudo cp /usr/share/doc/netplan/examples/wireless.yaml /etc/netplan/
sudo vi /etc/netplan/wireless.yaml (remove line 'addresses')
sudo netplan try
ip addr

# UPS Auto Shutdown Setup
# https://dl4jz3rbrsfum.cloudfront.net/documents/CyberPower_UM_PPP-Linux-v1.4.1.pdf
# https://www.cyberpowersystems.com/product/software/powerpanel-for-linux/
wget -P /tmp https://dl4jz3rbrsfum.cloudfront.net/software/PPL_64bit_v1.4.1.tar..gz
sudo tar -xvzf /tmp/PPL_64bit_v1.4.1.tar..gz -C /tmp
cd /tmp/powerpanel-1.4.1
sudo ./install.sh

## Configure the setting when the low battery event occurs.
### Shutdown at 300s left
sudo pwrstat -lowbatt -runtime 300 -active on -cmd /etc/pwrstatd-lowbatt.sh -duration 1 -shutdown on
### Power failure for 3600s
sudo pwrstat -pwrfail -delay 3600 -active on -cmd /etc/pwrstatd-powerfail.sh -duration 1 -shutdown on

##  Configure the connection to PowerPanel Cloud.
sudo pwrstat -cloud -active on -account EMAIL_ACCOUNT -password 'CYBERPOWER_PASSWORD'
sudo pwrstat -verify

# Test
sudo pwrstat -test

## Log
sudo tail -f /var/log/pwrstatd.log

## Install mailutils
### Select "Internet" option next
sudo apt install mailutils

### Add Discord notification
#### Download
wget https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/discord_notify.sh && chmod +x discord_notify.sh

#### Add this to the bottom of this file /etc/pwrstatd-lowbatt.sh
# Calling custom script
/home/mvuong/discord_notify.sh "Warning: The UPS's battery power is not enough, system will be shutdown soon!"

#### Add this to the bottom of this file /etc/pwrstatd-powerfail.sh
# Calling custom script
/home/mvuong/discord_notify.sh "Warning: Utility power failure has occurred for a while, system will be shutdown soon!"



# Fix route table
sudo ip route del default