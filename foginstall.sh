#!/bin/bash

# Run flightcheck.sh first

# Get variables to set up MySQL/MariaDB
echo "Enter the password you'd like to use as the MySQL root password"
read -s sql

echo "Enter the password you'd like to use as the FOG user password"
read -s fogsql

# Set MySQL/MariaDB root pwd
mysql -u root
use mysql;
update user set password=PASSWORD("$sql") where User='root';
flush privileges;
exit

# Automated mysql_secure_installation
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$sql\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

# Shut off SELinux of not already
sed -i -e 's/enforcing/permissive/g' /etc/selinux/config

# More turning off of SELinux
setenforce 0

# Start the install
cd /opt
mkdir git
cd git
git clone --depth 1 https://github.com/FOGProject/fogproject.git
cd fogproject/bin

# Automated install
FOG=$(expect -c"
set timeout 30
spawn ./installfog.sh
expect \"Choice\"
send \"1\r\"
expect \"What type of installation would you like to do?\"
send \"N\r\"
expect \"What is the IP address to be used by this FOG Server?\"
send \"r\"
expect \"If you are not sure, select No.\"
send \"r\"
expect \"Would you like to setup a router address for the DHCP server?\"
send \"n\r\"
expect \"      the DHCP server and client boot image?\"
send \"n\r\"
expect \"Would you like to use the FOG server for DHCP service?\"
send \"n\r\"
expect \"you like to install the additional language packs?\"
send \"n\r\"
expect \"Would you like to donate computer resources to the FOG Project?\"
send \"n\r\"
expect \"Are you sure you wish to continue\"
send \"y\r\"
expect eof
")
