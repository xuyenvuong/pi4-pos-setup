# UBUNTU OS SETUP (Pi)

## Install Ubuntu

[Download latest Ubuntu 64-bit](https://ubuntu.com/download/raspberry-pi)

[Using Rufus to flash the microSD card]

---
## 2.5G NIC card setup
Ref: 
1.  https://installati.one/install-r8125-dkms-ubuntu-22-04/?expand_article=1
1.  https://bbs.archlinux.org/viewtopic.php?id=264742

```bash
sudo apt update
sudo apt -y install r8125-dkms
ip a
# Change ethxxxx to whatever NIC card
sudo ethtool -s ethxxxx autoneg on advertise 0x80000000002f
# Check for "2500baseT/full" and "Speed: 2500Mb/s"
sudo ethtool ethxxxx
```

## Firmware Upgrades
```bash
sudo fwupdmgr get-upgrades
sudo fwupdmgr refresh --force
sudo fwupdmgr update
```

---
## Create User 
### Login with default ubuntu/ubuntu
```bash
ssh ubuntu@local_ip_address
# Change default password
passwd
```

### Add new user (other than default user 'ubuntu')
```bash
sudo adduser username
```

### Delete default user (default 'ubuntu')
```bash
sudo userdel -r username
```

### Give ubuntu user sudo access
```bash
# Add user to sudoer group
sudo usermod -aG sudo username

sudo EDITOR=vim visudo
# Add this line at the bottom of the file
# username  ALL=(ALL) NOPASSWD:ALL
```

### SSH only for matched user
```bash
# Add this block at the end of /etc/ssh/sshd_config file
# PubkeyAcceptedAlgorithms +ssh-rsa
#
# Match User username Address 192.168.0.0/24,10.8.0.0/24
#        PubkeyAuthentication yes
#        AuthorizedKeysFile %h/.ssh/authorized_keys
#        AuthenticationMethods publickey
#        PubkeyAcceptedKeyTypes +ssh-rsa

# Next set 
# PasswordAuthentication no

# Copy the public key to ~/.ssh/authorized_keys file

# Restart SSH
sudo systemctl restart ssh

# Open another console to check. If not working, revert
```

### Change hostname 
```bash
sudo vi /etc/hostname
sudo vi /etc/hosts
```
---

## SSD Setup
### Partition
```bash
sudo fdisk -l
sudo mkfs.ext4 /dev/sda
sudo mkdir -p /mnt/ssd
sudo mount /dev/sda /mnt/ssd
```
### Speed test (optional)
```bash
sudo hdparm --direct -t -T /dev/sda
```
### Auto mount
```bash
sudo blkid
```
#### Copy the UUID e.g. e087e709-20f9-42a4-a4dc-d74544c490a6
```bash
sudo vi /etc/fstab
```
#### Add this line at the end with the above UUID
```bash
# UUID=e087e709-20f9-42a4-a4dc-d74544c490a6   /mnt/ssd   ext4   defaults   0   2
```
### Reboot then check
```bash
df -hl
```
---

## Memory Allocation
### Memory Swap
```bash
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Set permanent during boot
sudo vi /etc/fstab

# Add line at the end
# /swapfile swap swap defaults 0 0

# Verify
sudo swapon --show
sudo free -h

# Adjust swappiness value to 10
cat /proc/sys/vm/swappiness
sudo sysctl vm.swappiness=10
sudo vi /etc/sysctl.conf

# Add permanent line at the end
# vm.swappiness=10
sudo shutdown -r now
```
---