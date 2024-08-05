
# Installation reference guide
*  https://raspberrytips.com/openmediavault-on-raspberry-pi/
# Alternative guide
*  https://pimylifeup.com/raspberry-pi-openmediavault/

# Installation 
# NOTE: Installation must be done thru ethernet (NOT WiFi)
> sudo apt update && sudo apt upgrade
> sudo wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash

# Open GUI - 
*  Login with `admin` & `openmediavault`
*  Change password, Set Dark Mode

# Generate SSL - 
*  Goto: `openmediavault -> System -> SSL`
*  Expiration: `10 Years`
*  Select Country: `United States`

# Setup HTTPS - openmediavault -> System -> Workbench
*  Check `SSL/TSL enable` box
*  Select default certificate
*  Check `Force SSL/TSL` box

# Setup Disk 
*  Goto: `openmediavault -> Storage -> Disks`
*  Select each device then wipe them clean first
*  Goto: `openmediavault -> Storage -> File systems`
*  Add all physical devices with type `EXT4`
*  Note: (In SSH console double check under `/srv/` folder)

# Setup SMB/CIFS
*  Goto: `openmediavault -> Services -> SMB/CIFS -> Settings -> Enable`
*  Check `Enable NetBIOS` box
*  Save
*  Goto: `openmediavault -> Services -> SMB/CIFS -> Shares -> Create`
*  Shared folder: `contents`
*  Comment: `contents folder`
*  Uncheck `Hide dot files`
*  Save

# Setup MergerFS
*  Guide: `https://www.networkshinobi.com/snapraid-and-mergerfs-on-openmediavault/`
*  Goto: `openmediavault -> System -> Plugins`
*  Install `openmediavault-mergerfs 7.0.5`
*  Goto: `openmediavault -> Storage -> mergerfs`
*  Click Add, 
*  name: `unionfs`
*  Note: (In SSH console double check under `/srv/mergerfs/unionfs` folder)
*  Filesystem: Only select the driver with data, and leave the backup alone for SMB/CIFS setup
*  Save

        # Setup SnapRAID
        *  Guide: `https://forum.openmediavault.org/index.php?thread/5553-snapraid-plugin-guide/`
        *  Goto: `openmediavault -> System -> Plugins`
        *  Install plugin: `openmediavault-snapraid 7.0.10`
        *  Goto: `openmediavault -> Services -> SnapRAID -> Arrays -> Create`
        *  Name: `set1`
        *  Save
        *  Goto: `openmediavault -> Services -> SnapRAID -> Drives -> Create`
        *  Array: `set1`
        *  Drive: `unionfs`
        *  Name: `mainraid`
        *  Check `Content` box
        *  Check `Data` box
        *  Save
        *  Goto: `openmediavault -> Services -> SnapRAID -> Drives -> Create`
        *  Array: `set1`
        *  Drive: `/dev/sdb1` (or any parity device/drive)
        *  Name: `parity1` (or parity2, etc...)
        *  Check `Parity` box
        *  Save
        *  Goto: `openmediavault -> System -> Schedule Tasks`
        *  Select and Edit SnapRAID task
        *  Check `Enable` box
        *  Time of execution: `Daily`
        *  Save

# OMV-Extra Setup
# https://forum.openmediavault.org/index.php?thread/48003-guide-using-the-new-docker-plugin/
*  Goto: `openmediavault -> Storage -> Shared Folders`
*  Create a folder called `compose`
*  Select `unionfs`
*  Save
*  Goto: `openmediavault -> System -> omv-extras`
*  Check Docker repo box
*  Save
*  Click `apt-clean`

# Docker Compose
*  Goto: `openmediavault -> System -> Plugins`
*  Install plugin: `openmediavault-compose 7.2.1`
*  Goto: `openmediavault -> Services -> Compose -> Settings`
*  Under Compose Files -> Shared folder, select `compose`
    *  Change Owner of directories and files to `mvuong` and group `users` (not `root`)
*  Save
*  Click `Restart Docker`
*  Goto SSH console and run these commands:
*  `sudo chown $USER /var/run/docker.sock`
*  `sudo groupadd docker`
*  `sudo usermod -aG docker $USER`

# Jellyfin Setup
```yaml
---
services:
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=1000
      - PGID=100
      - TZ=Etc/UTC
      - JELLYFIN_PublishedServerUrl=192.168.0.5 #optional
    volumes:
      - /srv/dev-disk-by-uuid-e2efdf44-41ae-4887-9018-0772c6554c5f/appdata:/config
      - /srv/dev-disk-by-uuid-e2efdf44-41ae-4887-9018-0772c6554c5f/contents/media:/data/tvshows
      - /srv/dev-disk-by-uuid-e2efdf44-41ae-4887-9018-0772c6554c5f/contents/media:/data/movies
    ports:
      - 8096:8096
      - 8920:8920 #optional
      - 7359:7359/udp #optional
      - 1901:1901/udp #optional org 1900:1900
    devices:
      - /dev/video10:/dev/video10
      - /dev/video11:/dev/video11
      - /dev/video12:/dev/video12
    restart: unless-stopped
```
# Setup Jellyfin on Samsung TV (Developer Mode)
*  Goto: `https://docs.tizen.org/`
*  Register a developer account (same as your Samsung TV login)
*  Download and install: `Tizen Studio` - Install `SDK SDK Tools`

*  Turn on Samsung Developer mode:
*  Guide: `https://developer.samsung.com/smarttv/develop/getting-started/using-sdk/tv-device.html`

*  Goto: `https://github.com/jeppevinkel/jellyfin-tizen-builds/releases`
*  Download file: `Jellyfin.wgt` (note: exact filename)

*  Note: Copy the `Jellyfin.wgt` to `C:\tizen-studio\tools\ide\bin`
*  Open CMD: run: `tizen install -n Jellyfin.wgt -t <NAME>` (where `NAME` e.g. QNXXXXXXXXX)
*  Done.

#  Conifg Jellyfin app
*  Go to `Jellyfin app -> Playback -> Transcoding`
*  Hardware acceleration: `Video4Linux2(V4L2)`
*  Add Repo: `https://github.com/danieladov/jellyfin-plugin-skin-manager`
*  (Check for latest release info `https://github.com/jeppevinkel/jellyfin-tizen-builds/releases`)
*  Then install `Skin Manager` plugin
*  Done

# Setup Users
*  Goto: `openmediavault -> Users`
*  Select a user (e.g. `mvuong`) and set password.
*  Use phone app to test SMB connection using the same credentials.
*  Add new user (different from system users)
*  Set the `password`
*  Set shell: `/usr/bin/nologin`
*  Groups: `users`
*  Goto: `openmediavault -> Users`
*  Then select each users and set their appropriate `Shared Folder Permission` (R/W)
*  Check to make sure. Using Windows Explorer or SMB on phone to check.

# MiniDLNA (Optional)
*  Goto: `openmediavault -> System -> Plugins`
*  Install `openmediavault-minidlna 7.0`
*  Just need to enable, then share the folder.
*  Done

# FolderSync App (Client side sync)
*  Install `FolderSync` app from the AppStore
*  Config to sync to OMV.
*  Done.

# RSync Setup
*  Guide: `https://docs.openmediavault.org/en/5.x/new_user_guide/newuserguide.html#backups-and-backup-strategy`

# Backup and Restore
*  Backup guide: `https://forum.openmediavault.org/index.php?thread/44909-how-to-backup-omv-system-configuration/`
*  System-Rescue download: `https://www.system-rescue.org/`
*  Restore Guide: `https://forum.openmediavault.org/index.php?thread/43774-how-to-restore-omv-system-backup-made-with-openmediavault-backup-plugin/`
*  Using `rclone` guide: `https://linuxpip.org/rclone-examples`
*  Installation: `https://rclone.org/install/`