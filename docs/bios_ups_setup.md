<style>
r { color: Red }
o { color: Orange }
g { color: Green }
</style>

# BIOS Power Restore and UPS Auto Shutdown Setup

---
## BIOS: Restore on AC/Power Loss

If you haven't adjust your Staking-Server's BIOS to auto restart after a power failure, then you should do so to avoid server offline forever.

1. Reboot your server and enter BIOS mode.
1. Inside BIOS menu, look under the following menus to find for a setting named <o>_**“Restore on AC/Power Loss”**_</o> or <o>_**“AC Power Recovery”**_</o> or <o>_**"After Power Loss"**_</o>. Or <o>_**“Advanced” or “ACPI”**_</o> or <o>_**"Power Management Setup"**_</o>.
1. Set the <g>_**“Restore on AC/Power Loss”**_</g> setting to <g>_**“Power On”**_</g> or <g>_**“Last State”**_</g>
1. Save BIOS and restart the server.
1. DONE

---

---

## UPS Auto Shutdown

Using a UPS is great if you have a power outage, but if you haven't yet config your UPS to auto shutdown your server while you are not around to do a manual shutdown, your must do it now so that you won't get a corrupted DB if your UPS is running out of power. 

Depends on your UPS brand, the setup will vary, however it's fundamentally the same.
<r>_(Note: check with me if you need help)_</r>

For the <g>CyberPower</g> brand

<img src="https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fmedia.glassdoor.com%2Fsqll%2F915029%2Fcyberpower-global-squarelogo-1515454061052.png&f=1&nofb=1&ipt=a53f7d4fe7ed0e1b71533a12bae45e9eaed86a6d2875a5e5ca5a7a2d95031d80&ipo=images" width="60px" title="CyberPower" alt="CyberPower Logo" />

First, connect your UPS to your server via USB port.

### On Linux (Ubuntu 20.04 or better), download: 
```bash
wget -P /tmp https://dl4jz3rbrsfum.cloudfront.net/software/PPL_64bit_v1.4.1.tar..gz

sudo tar -xvzf /tmp/PPL_64bit_v1.4.1.tar..gz -C /tmp

cd /tmp/powerpanel-1.4.1

sudo ./install.sh

# To check, run
sudo pwrstat -status
```
### Test UPS, run
```bash
sudo pwrstat -test

# To check, run
sudo pwrstat -status
```


### Configure:
#### Low Battery Shutdown at 300s (5 mins) left on remaining Power:
```bash
sudo pwrstat -lowbatt -runtime 300 -active on -cmd /etc/pwrstatd-lowbatt.sh -duration 1 -shutdown on

# Config the script (enter your email info)
sudo vi /etc/pwrstatd-lowbatt.sh
```

#### Power Failure for 3600s (1hr or config to whatever your UPS capacity can hold)
```bash
sudo pwrstat -pwrfail -delay 3600 -active on -cmd /etc/pwrstatd-powerfail.sh -duration 1 -shutdown on

# Config the script (enter your email info)
sudo vi /etc/pwrstatd-powerfail.sh
```

#### Make the same settings for the daemon
```bash
sudo vi /etc/pwrstatd.conf

# To reload the daemon, run this after you save:
sudo /etc/init.d/pwrstatd restart
```

#### Configure the connection to PowerPanel Cloud.
Register an cloud account with CyberPower here [https://www.cyberpower.com](https://www.cyberpower.com)
```bash
sudo pwrstat -cloud -active on -account 'EMAIL_ACCOUNT' -password 'CYBERPOWER_PASSWORD'

sudo pwrstat -verify

# There are three results, described below:
# 1. When both the account and password are correct, the system will show Verify successfully.
# 2. When either the account or password is incorrect, the system will show Verify failed.
# 3. When a network issue exists, the system will show Connect failed.
```

Download PowerPanel Cloud app on the App Store (iOS, Android, Web) and login to see your UPS' performance.

1. iOS: [PowerPanel Cloud](https://apps.apple.com/us/app/powerpanel-cloud/id1342462532)
1. Android: [PowerPanel Cloud](https://play.google.com/store/apps/details?id=com.cyberpower.pppe&gl=US)

----

### Add Discord notification
#### Download
```bash
wget https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/discord_notify.sh && chmod +x discord_notify.sh
```

#### Add this to the bottom of this file __**/etc/pwrstatd-lowbatt.sh**__
```bash
# Calling custom script
/home/YOUR_LOGIN_NAME/discord_notify.sh "Warning: The UPS's battery power is not enough, system will be shutdown soon!"
```

#### Add this to the bottom of this file __**/etc/pwrstatd-powerfail.sh**__
```bash
# Calling custom script
/home/YOUR_LOGIN_NAME/discord_notify.sh "Warning: Utility power failure has occurred for a while, system will be shutdown soon!"
```

---
DONE
---