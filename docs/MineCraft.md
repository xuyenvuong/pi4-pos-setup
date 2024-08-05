
```bash
# Install Pi OS (64 bits) Server
# Tune-Up (SD overclocking) - https://jamesachambers.com/raspberry-pi-dedicated-minecraft-v1-12-server-excellent-performance-guide/
sudo vim /boot/firmware/config.txt
  # Overclock the SD card port to 100hz
  dtparam=sd_overclock=100

# Guide: https://linuxize.com/post/how-to-install-minecraft-server-on-raspberry-pi/
sudo apt update
sudo apt upgrade
sudo apt install git build-essential

# Java: `https://pimylifeup.com/raspberry-pi-java/`
sudo apt install curl gnupg ca-certificates
curl -s https://repos.azul.com/azul-repo.key | sudo gpg --dearmor -o /usr/share/keyrings/azul.gpg
echo "deb [arch=arm64 signed-by=/usr/share/keyrings/azul.gpg] https://repos.azul.com/zulu/deb stable main" | sudo tee /etc/apt/sources.list.d/zulu.list

sudo apt update
sudo apt install zulu21-jdk-headless
java --version

sudo apt install default-jre

# User
sudo useradd -r -m -U -d /opt/minecraft -s /bin/bash minecraft
sudo su - minecraft

# Working dirs
mkdir ~/{tools,server}

# Tools
cd ~/tools
git clone https://github.com/Tiiffi/mcrcon.git
cd mcrcon
gcc -std=gnu11 -pedantic -Wall -Wextra -O2 -s -o mcrcon mcrcon.c
./mcrcon -h

# Server - `https://papermc.io/downloads/paper` or here `https://www.minecraft.net/en-us/download/server`
cd ~/server
wget -P /tmp https://api.papermc.io/v2/projects/paper/versions/1.21/builds/124/downloads/paper-1.21-124.jar
java -jar paper-1.21-124.jar
sed -i ‘s/eula=false/eula=true/’ eula.txt

# Configs `https://raspberrytips.com/minecraft-server-raspberry-pi/`
vim server.properties
  rcon.port=25575
  rcon.password=P@ssw0rd
  enable-rcon=true

# (optional configs)
vim spigot.yml (optional)
vim bukkit.yml

# Daemon service
sudo cat << EOF | sudo tee /etc/systemd/system/minecraft.service >/dev/null
[Unit]
Description=Minecraft Server
After=network.target

[Service]
User=minecraft
Nice=1
SuccessExitStatus=0 1
ProtectHome=true
ProtectSystem=full
PrivateDevices=true
NoNewPrivileges=true
WorkingDirectory=/opt/minecraft/server
ExecStart=/usr/bin/java -server -XX:+UseG1GC -Xmx2G -Xms1G -jar paper-1.21-124.jar nogui
ExecStop=/opt/minecraft/tools/mcrcon/mcrcon -H 127.0.0.1 -P 25575 -p xxxxxxxxxx stop

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start minecraft.service
sudo systemctl enable minecraft.service



# Accessing Minecraft Console
vim .bashrc
alias minecraft-console="/opt/minecraft/tools/mcrcon/mcrcon -H 127.0.0.1 -P 25575 -p xxxxxxxxxx -t" 
```

# At console run:
> wb world set 1000 spawn 
> wb world fill 1000 
> wb fill confirm
# Wait & Quit
> Q

# Open NAT forward port 25565

# Install plugins

# TODO: Backup
https://www.spigotmc.org/resources/backupplus-discontinued.45985/
https://raspberrytips.com/backup-raspberry-pi/
https://raspberrytips.com/how-to-clone-raspberry-pi-sd-card/