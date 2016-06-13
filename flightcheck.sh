#!/bin/bash

clear

# Check distribution before installing packages
OS=`grep -Eiom 1 'CentOS|RedHat|Ubuntu' /proc/version`

# Check for Systemd vs sysvinit
SYS=`ps -p 1 -o cmd h`

# Check if user is root, if not tells them to sudo su
if [ "$USER" != "root" ]; then
		echo 'WARNING! This script should be run as root'
		echo 'Please enter sudo su and run the script again'
else
	if [ "$OS" == "centos" -a "redhat" ]; then
	{
	  # Update everything currently installed
		yum -y update

		# Turn off SELinux for now
		setenforce 0

		# Shut off SELinux if not already
		sed -i -e 's/enforcing/permissive/g' /etc/selinux/config

		# More basics that should be installed for ease of use
		yum -y install git vim htop wget openssh net-tools epel-release firewalld
		
		# Webtatic
		wget https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
		rpm --import https://mirror.webtatic.com/yum/RPM-GPG-KEY-webtatic-el7
		rpm -K webtatic-release.rpm
		rpm -Uvh webtatic-release.rpm
		yum update
	} > ~/flightcheck_log
		# Prompt if LAMP stack needed

		echo 'Is a LAMP stack required? [y/n]'
		read stack
	
		if [ "$stack" == "y" ]; then
	{		# Basics for Linux servers, LAMP stack
			yum -y install httpd httpd-tools mariadb mariadb-server php php-common php-gd php-xmlrpc php-xml expect openssl openssl-devel
			
			# Starts Apache2 and MariaDB/MySQL with Systemd or init script

			if [ "$SYS" == "systemd" ]; then
				systemctl start httpd && systemctl enable httpd
				systemctl start mariadb && systemctl enable mariadb
			elif [ "$SYS" == "sysvinit" ]; then
				service httpd start && chkconfig httpd on
				service mariadb start && chkconfig mariadb on
			fi
	} >> ~/flightcheck_log		
		else
			echo 'Moving on'
		fi
	{
		# Install development tools
		yum -y groupinstall "Development tools"
	} >> ~/flightcheck_log
	
	echo 'Done. Check flightcheck_log for more details'

	elif [ "$OS" == "ubuntu" ]; then
	{
		# Update everything currently installed
		apt-get -y update; apt-get -y upgrade

		# Turn off SELinux for now
		setenforce 0
		
		# Install basics for ease of use
		apt-get -y install git vim htop wget openssh net-tools

		# Shut off SELinux if not already
		sed -i -e 's/enforcing/permissive/g' /etc/selinux/config

		# Prompt if LAMP stack is required
	} > ~/flightcheck_log
		echo 'Is a LAMP stack required? [y/n]'
		read stack
	{
		if [ "$stack" == "y" ]; then
			# Basics for Linux servers, LAMP stack
			apt-get -y install apache2 apache2-utils mysql-server php5 php5-common php5-gd php5-xmlrpc php5-xml expect openssl openssl-devel
				
			# Starts Apache2 and MariaDB/MySQL with Systemd or init script
			if [ "$SYS" == "systemd" ]; then
				systemctl start apache2 && systemctl enable apache2
				systemctl start mysql && systemctl enable mysql
			elif [ "$SYS" == "sysvinit" ]; then
				service apache2 start && chkconfig apache2 on
				service mysql start && chkconfig mysql on
			fi
	} >> ~/flightcheck_log
		else
			echo 'Moving on'
		fi
	{
		# Install development tools
		apt-get -y install build-essentials

	} >> ~/flightcheck_log
		echo 'Done. Check flighcheck_log for more details'
	else
		echo 'Supported OS Not Detected'
	fi
fi
