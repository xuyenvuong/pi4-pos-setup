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
#
# Match User username
#        PubkeyAuthentication yes
#        AuthorizedKeysFile %h/.ssh/authorized_keys
#        AuthenticationMethods publickey

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
# net.core.rmem_max = 7500000
# net.core.wmem_max = 7500000
sudo shutdown -r now
```

## Pi-KVM
# Samba fstab mount
```bash
# PiKVM and OS update
pikvm-update
rw
pacman -Syy
pacman -S pikvm-os-updater
pikvm-update

# Tailscale
rw
pacman -S tailscale-pikvm
systemctl enable --now tailscaled
tailscale up --ssh
reboot

# Samba setup
rw
pacman -S cifs-utils
kvmd-helper-otgmsd-remount rw
mkdir -p /var/lib/kvmd/msd/isos
kvmd-helper-otgmsd-remount ro

# Samba automount via fstab, or by systemd (look below)
vi /etc/fstab
#//192.168.1.167/contents/software/isos /var/lib/kvmd/msd/isos cifs ro,vers=3.1.1,noauto,x-systemd.automount,x-systemd.device-timeout=10,credentials=/root/.smbcredentials 0 0
ro
reboot

# Or, Samba as systemd
# https://anteru.net/blog/2019/automatic-mounts-using-systemd/
rw

# Disable any unused interface to speed up boot.
systemctl edit systemd-networkd-wait-online.service
# Add these below lines in the top section (between the editable lines)
# [Service]
# Type=oneshot
# ExecStart=
# ExecStart=/usr/lib/systemd/systemd-networkd-wait-online --ignore=eth0
# RemainAfterExit=yes

cat << EOF | sudo tee /root/.smbcredentials
username=<username>
password=<password>
EOF
# Put username/password

# Must use local IP e.g. 192.168.1.167 instead of Tailscale DNS
cat << EOF | sudo tee /etc/systemd/system/var-lib-kvmd-msd-isos.mount >/dev/null
[Unit]
Description=isos mount

[Mount]
What=//192.168.1.167/contents/software/isos
Where=/var/lib/kvmd/msd/isos
Type=cifs
Options=ro,vers=3.1.1,noauto,credentials=/root/.smbcredentials
DirectoryMode=0700

[Install]
WantedBy=multi-user.target
EOF

cat << EOF | sudo tee /etc/systemd/system/var-lib-kvmd-msd-isos.automount >/dev/null
[Unit]
Description=isos automount

[Automount]
Where=/var/lib/kvmd/msd/isos

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable var-lib-kvmd-msd-isos.mount
systemctl enable var-lib-kvmd-msd-isos.automount

ro
reboot
```
---