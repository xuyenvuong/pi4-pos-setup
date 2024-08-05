INSTALLATION
https://homenetworkguy.com/how-to/install-and-configure-opnsense/

SECURED ACCESS
https://homenetworkguy.com/how-to/ways-to-secure-access-to-opnsense-and-your-home-network/

MULTIFACTOR ACCESS
https://homenetworkguy.com/how-to/enable-multi-factor-authentication-in-opnsense/

SELF SIGN CERTIFICATE FOR OPNsense WEB
https://homenetworkguy.com/how-to/replace-opnsense-web-ui-self-signed-certificate-with-lets-encrypt/

VLAN
https://homenetworkguy.com/how-to/configure-vlans-opnsense/

VLAN FIREWALL RULES
https://homenetworkguy.com/how-to/firewall-rules-cheat-sheet/
Example: https://docs.opnsense.org/manual/how-tos/guestnet.html

PORT FORWARDING
https://www.wundertech.net/how-to-port-forward-in-opnsense/

FREE MY IP - free domain
https://freemyip.com/update?token=5b29...7520&domain=customddns.freemyip.com

```bash
# On servers
# Configuration for freemyip.com
custom=yes
server=freemyip.com
protocol=dyndns2
login=5b29...7520
password=5b29...7520
customddns.freemyip.com
```

```bash
# On Opensense router /usr/local/etc/ddclient.conf
use=if, if=igc0
use=web, web=freemyip.com/checkip
protocol=dyndns2 \
server=freemyip.com \
login=5b29...7520 \
password=5b29...7520 \
customddns.freemyip.com
```

DDNS
https://forum.opnsense.org/index.php?topic=26446.195
https://homenetworkguy.com/how-to/configure-dynamic-dns-opnsense/

CUSTOM DOMAIN
https://homenetworkguy.com/how-to/use-custom-domain-name-in-internal-network/

ACCESS DDNS on LAN
https://forum.opnsense.org/index.php?topic=1884.0

OPENVPN SETUP
https://homenetworkguy.com/how-to/configure-openvpn-opnsense/

WIREGUARD VPN SETUP
https://homenetworkguy.com/how-to/configure-wireguard-opnsense/

COMCAST CABLE MODEM ISSUE FIX
# Only use it if there's random modem reboot issue)
System->Settings->Tunables
net.link.ether.inet.max_age=120

INTRUSION DETECTION
https://homenetworkguy.com/how-to/configure-intrusion-detection-opnsense/

TROUBLESHOOTING
https://docs.opnsense.org/troubleshooting/webgui.html
# Restart GUI
> configctl webgui restart renew

ADGUARD SETUP
https://windgate.net/setup-adguard-home-opnsense-adblocker/
# Configs tips
https://www.smarthomebeginner.com/adguard-home-configuration-tips/
# Block lists
https://firebog.net/

# HAPROXY SETUP
*  https://www.youtube.com/watch?v=uACQrhtsgFk
*  https://www.duckdns.org/domains
*  Info is in BitWarden

*  Note: Generate specific certificate for each subdomain (instead of wildcard domain) to prevent wrong site loading issue.
*  Info here: https://forum.opnsense.org/index.php?topic=24055.0;prev_next=prev#new

# https://community.spiceworks.com/t/opnsense-haproxy-as-reverse-proxy-for-self-hosted-services/1013494
# https://forum.opnsense.org/index.php?topic=23339.msg110962#msg110962

# TROUBLESHOOT
# NOTE: If GUI doesn't start, try to run this command, then resolve any Permission Denied issue:
* `sudo /usr/local/sbin/lighttpd -f /var/etc/lighty-webConfigurator.conf`