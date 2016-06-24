#!/bin/bash

clear

# Check distribution before installing packages
OS=`grep -Eiom 1 'CentOS|RedHat|ol|Ubuntu|debian|Fedora|suse|amzn' /proc/version | head -1 | tr '[:upper:]' '[:lower:]'`

# Check for Systemd vs sysvinit
SYS=`ps -p 1 | grep -Eiom 1 'systemd|init'`

# Check for web server software and DB engine
srv=`ls /etc | grep -Eiom 1 'Apache2|httpd|nginx|lighttpd'`
db=`ls /var/lib | grep -Eiom 1 'mysql|pgsql' | head -1`

# Sets variables for dialog box
cmd=(dialog --separate-output --checklist "Select software to install:" 22 76 16)
options=(1 "WordPress" off
         2 "Drupal 7" off
         3 "Drupal 8" off
         3 "Joomla!" off)

if [ "$USER" != 'root' ]; then
  echo 'WARNING! This script should be run as root'
  echo 'Please enter sudo su and run the script again'
else

if [ "$OS" == 'centos' ]; then
  echo 'CentOS Detected'
elif [ "$OS" == 'redhat' ]; then
  echo 'RHEL Detected'
elif [ "$OS" == 'ol' ]; then
  echo 'Oracle Linxu Detected'
elif [ "$OS" == 'amzn' ]; then
  echo 'Amazon Linux AMI Detected'
elif [ "$OS" == 'ubuntu' ]; then
  echo 'Ubuntu Detected'
elif [ "$OS" == 'debian' ]; then
  echo 'Debian Detected'
elif [ "$OS" == 'fedora' ]; then
  echo 'Fedora Detected'
elif [ "$OS" == 'suse' ]; then
  echo 'OpenSUSE Detected'
else
  echo 'Supported OS Not Detected'
  exit
fi

echo 'Make sure you run flightcheck.sh and hydrationv2.sh first'
sleep 2

choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear

for choice in $choices
do

case $choice in

1)
  echo 'Installing WordPress...'
  { # Creates base directory and downloads latest tarball
    mkdir -p /var/www/wordpress
    wget https://wordpress.org/latest.tar.gz && tar xzf latest.tar.gz -C /var/www/wordpress
    
