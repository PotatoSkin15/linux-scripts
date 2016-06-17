#!/bin/bash

clear

# Check distribution before installing packages
OS=`grep -Eiom 1 'CentOS|RedHat|el.uek|Ubuntu|Fedora|SUSE|amzn' /proc/version | head -1 | tr '[:upper:]' '[:lower:]'`

# Check for Systemd vs sysvinit
SYS=`ps -p 1 | grep -Eiom 1 'systemd|init'`

# Check if user is root, if not tells them to sudo su
if [ "$USER" != "root" ]; then
		echo 'WARNING! This script should be run as root'
		echo 'Please enter sudo su and run the script again'
else
	if [ "$OS" == 'centos' -a 'redhat' -a "el.uek" -a 'fedora' -a 'amzn' ]; then
	echo 'Red Hat Derivative Detected'
	echo 'Processing...'
	{
	  # Update everything currently installed
		yum -y update

		# Turn off SELinux for now
		setenforce 0

		# Shut off SELinux if not already
		sed -i -e 's/enforcing/permissive/g' /etc/selinux/config

		# More basics that should be installed for ease of use
		yum -y install git vim htop wget openssh net-tools epel-release firewalld zip bzip2

		# Webtatic
		wget https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
		rpm --import https://mirror.webtatic.com/yum/RPM-GPG-KEY-webtatic-el7
		rpm -K webtatic-release.rpm
		rpm -Uvh webtatic-release.rpm
		yum update
	} >> ~/flightcheck_log
	echo 'Done. Check flightcheck_log for more details'

	elif [ "$OS" == 'ubuntu' ]; then
	echo 'Ubuntu Detected'
	echo 'Processing...'
	{
		# Update everything currently installed
		apt-get -y update && apt-get -y upgrade

		# Turn off SELinux for now
		setenforce 0

		# Install basics for ease of use
		apt-get -y install git vim htop wget openssh net-tools zip bzip2

		# Shut off SELinux if not already
		sed -i -e 's/enforcing/permissive/g' /etc/selinux/config

		# Install development tools
		apt-get -y install build-essentials

	} >> ~/flightcheck_log
	echo 'Done. Check flighcheck_log for more details'

	elif [ "$OS" == 'SUSE' ]; then
	echo 'OpenSUSE Detected'
	echo 'Processing...'
	{
		# Update everything currently installed
		zypper -n ref && zypper -n up

		# Install basics for ease of use
		zypper -n in git vim htop wget openssh net-tools zip bzip2

		# Install development tools
		zypper -n --type pattern devel_basis
	} >> ~/flightcheck_log
	echo 'Done. Check flightcheck_log for more details.'

	else
		echo 'Supported OS Not Detected'
	fi
fi
