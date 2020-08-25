# pi4-pos-setup
# Download installation script
> wget -NS --content-disposition --no-check-certificate https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/setup.sh && chmod +x setup.sh
or
> curl https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/setup.sh -o setup.sh && chmod +x setup.sh
> ./setup.sh install



shell> docker exec -it mysql mysql -uroot -p
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'P@ssw0rd';

mysql> CREATE USER 'posuser'@'localhost' IDENTIFIED BY 'P@ssw0rd';
mysql> GRANT ALL PRIVILEGES ON *.* TO 'posuser'@'localhost' WITH GRANT OPTION;
mysql> CREATE USER 'posuser'@'%' IDENTIFIED BY 'P@ssw0rd';
mysql> GRANT ALL PRIVILEGES ON *.* TO 'posuser'@'%' WITH GRANT OPTION;

mysql> ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'P@ssw0rd';
mysql> ALTER USER 'posuser'@'%' IDENTIFIED WITH mysql_native_password BY 'P@ssw0rd';

mysql> flush privileges;

mysql> CREATE DATABASE IF NOT EXISTS params;

# References:
# https://docs.python-guide.org/starting/install3/linux/