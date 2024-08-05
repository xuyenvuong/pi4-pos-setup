
# Setup server:
*  Use Pi image with (64 bit) server

*  `sudo apt update && sudo apt upgrade`
*  `sudo apt dist-upgrade`
*  `wget -P /tmp https://download.nextcloud.com/server/releases/latest.zip`

# Install mariadb-server
*  `sudo apt install mariadb-server`
*  `sudo mysql_secure_installation`
*  `sudo mariadb`
*  Run: `CREATE DATABASE nextcloud;`
*  Run: `SHOW DATABASES;`
*  Run: `GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost' IDENTIFIED BY 'ChangeThisPassword';`
*  Run: `FLUSH PRIVILEGES;`
*  Exit: Ctl+d

# Install PHP and Apache
*  `sudo apt install php php-apcu php-bcmath php-cli php-common php-curl php-gd php-gmp php-imagick php-intl php-mbstring php-mysql php-zip php-xml php-memcache php-apcu imagemagick`
*  `sudo phpenmod bcmath gmp imagick intl memcache apcu`

*  `unzip /tmp/latest.zip`
*  `sudo chown -R www-data:www-data nextcloud`
*  `sudo mv nextcloud /var/www/`

*  `sudo a2dissite 000-default.conf`
*  `sudo systemctl reload apache2.service`
*  `sudo vi /etc/apache2/sites-available/nextcloud.conf`
<VirtualHost *:80>
    DocumentRoot "/var/www/nextcloud"
    ServerName nextcloud

    <IfModule mod_headers.c>
        Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"
    </IfModule>

    <Directory "/var/www/nextcloud">
        Options MultiViews FollowSymlinks
        AllowOverride All
        Order allow,deny
        Allow from all
    </Directory>

    TransferLog /var/log/apache2/nextcloud.access.log
    ErrorLog /var/log/apache2/nextcloud.error.log

</VirtualHost>

*  `sudo a2ensite nextcloud.conf`

*  `sudo vi /etc/php/8.2/apache2/php.ini`
*  memory_limit = 512M
*  upload_max_filesize = 200M
*  max_execution_time = 360
*  post_max_size = 200M
*  date.timezone = America/Los_Angeles
*  opcache.enable = 1
*  opcache.interned_strings_buffer=8
*  opcache.max_accelerated_files=1000
*  opcache.memory_sonsumption=128
*  opcache.save_comments=1
*  opcache.revalidate_freq=1

*  `sudo a2enmod dir env headers mime rewrite ssl`
*  `sudo systemctl restart apache2.service`

*  `sudo vi /var/www/nextcloud/config/config.php`
*  'memcache.local' => '\OC\Memcache\APCu',
*  'maintenance_window_start' => 1,
*  'memcache.locking' => '\OC\Memcache\APCu',
*  'default_phone_region' => 'US',

*  `sudo chmod 660 /var/www/nextcloud/config/config.php`
*  `sudo chown root:www-data /var/www/nextcloud/config/config.php`

*  `sudo vim /etc/php/8.0/mods-available/apcu.ini`
*  `apc.enable_cli=1`
*  `sudo systemctl restart apache2.service`

*  `sudo php /var/www/nextcloud/occ db:add-missing-indices`

*  `sudo vim /var/www/nextcloud/core/routes.php`
*  Add this to line 41: `$this->create('heartbeat', '/heartbeat');`

# Optional for SSL
*  `sudo apt install python3-certbot-apache`
*  `sudo certbot --apache -d whatever.domain.here.com`

# Connect to NAS (OMV)
*  Guide: `https://raspberrytips.com/map-network-drive-on-ubuntu/`
*  `sudo apt update`
*  `sudo apt install cifs-utils`
*  `sudo mount -o user=mvuong //192.168.1.167/nextcloud /mnt/omv`
*  `sudo vi /etc/fstab`
*  `//192.168.1.167/nextcloud /mnt/omv cifs user=mvuong,password=xxx,uid=1000 0 0`
*  Save
*  `sudo shutdown -r now`
