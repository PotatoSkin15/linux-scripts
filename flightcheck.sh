#!/bin/bash

clear

# Check distribution before installing packages
OS=`grep -Eiom 1 'CentOS|RedHat|ol|Ubuntu|Fedora|SUSE|amzn' /proc/version | head -1 | tr '[:upper:]' '[:lower:]'`

# Check for Systemd vs sysvinit
SYS=`ps -p 1 | grep -Eiom 1 'systemd|init'`

# Check if user is root, if not tells them to sudo su
if [ "$USER" != "root" ]; then
		echo 'WARNING! This script should be run as root'
		echo 'Please enter sudo su and run the script again'
else
	if [[ "$OS" == 'centos' || "$OS" == 'redhat' || "$OS" == 'amzn' ]]; then
		if [ "$OS" == 'centos' ]; then
			echo 'CentOS Detected'
		elif [ "$OS" == 'redhat' ]; then
			echo 'RHEL Detected'
		elif [ "$OS" == 'amzn' ]; then
			echo 'Amazon Linux AMI Detected'
		fi
	echo 'Processing...'
	ver=`grep -Eiom 1 'el6|el7' /proc/version | head -1`
	{
	  # Update everything currently installed
		yum -y update

		# Turn off SELinux for now
		setenforce 0

		# Shut off SELinux if not already
		sed -i -e 's/enforcing/permissive/g' /etc/selinux/config

		# More basics that should be installed for ease of use
		yum -y install git vim htop wget openssh net-tools firewalld zip bzip2 curl

		# Install Development tools
		yum -y groupinstall 'Development Tools'

		if [ "$ver" == 'el7' ]; then
			# EPEL
			wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
			rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7Server
			rpm -K epel-release-latest-7.noarch.rpm
			rpm -Uvh epel-release-latest-7.noarch.rpm
			yum update

			# Webtatic
			wget https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
			rpm --import https://mirror.webtatic.com/yum/RPM-GPG-KEY-webtatic-el7
			rpm -K webtatic-release.rpm
			rpm -Uvh webtatic-release.rpm
			yum update

		elif [ "$ver" == 'el6' ]; then
			# EPEL
			wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
			rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6Server
			rpm -K epel-release-latest-6.noarch.rpm
			rpm -Uvh epel-release-latest-6.noarch.rpm
			yum update

			# Webtatic
			wget https://mirror.webtatic.com/yum/el6/latest.rpm
			rpm --import https://mirror.webtatic.com/yum/RPM-GPG-KEY-webtatic-andy
			rpm -K latest.rpm
			rpm -Uvh latest.rpm
			yum update
		fi
	} &> ~/flightcheck_log
	echo 'Done. Check flightcheck_log for more details'

	elif [ "$OS" == 'fedora' ]; then
	echo 'Fedora Detected'
	echo 'Processing...'
	{
		# Update everything currently installed
		dnf check-update && dnf -y update

		# Installs tools needed to parse yum commands to dnf
		dnf install python-dnf-plugins-extras-migrate && dnf-2 migrate

		# Turn off SELinux for now
		setenforce 0

		# Shut off SELinux if not already
		sed -i -e 's/enforcing/permissive/g' /etc/selinux/config

		# Installs basics for ease of use
		dnf -y install git vim htop wget openssh-server net-tools zip bzip2 kernel-devel curl

		# Installs development tools
		dnf -y groupinstall "Development Tools"
		dnf -y groupinstall "C Development Tools and Libraries"

	} &> ~/flightcheck_log

	echo 'Done. Check flightcheck_log for more details'

	elif [ "$OS" == 'ol' ]; then
	echo 'Oracle Linux Detected'
	echo 'Processing...'
	{
		# Update everything currently installed
		yum -y update

		# Turn off SELinux for now
		setenforce 0

		# Shut off SELinux if not already
		sed -i -e 's/enforcing/permissive/g' /etc/selinux/config

		# More basics that should be installed for ease of use
		yum -y install git vim htop wget openssh net-tools epel-release firewalld zip bzip2 kernel-uek-devel curl

		yum -y groupinstall 'Development Tools'
	} &> ~/flightcheck_log
	echo 'Done. Check flightcheck_log for more details'

	elif [ "$OS" == 'ubuntu' ]; then
	echo 'Ubuntu Detected'
	echo 'Processing...'
	{
		# Update everything currently installed
		apt-get -y update && apt-get -y upgrade

		# Install basics for ease of use
		apt-get -y install git vim htop wget openssh-server net-tools firewalld zip bzip2 curl

		# Install development tools
		apt-get -y install build-essential

	} &> ~/flightcheck_log
	echo 'Done. Check flighcheck_log for more details'

elif [ "$OS" == 'suse' ]; then
	echo 'OpenSUSE Detected'
	echo 'Processing...'
	{
		# Update everything currently installed
		zypper -n ref && zypper -n up

		# Install basics for ease of use
		zypper -n in -R git vim htop wget openssh net-tools zip bzip2 kernel-default-devel curl

		# Install development tools
		zypper -n in -R -t pattern devel_basis
	} &> ~/flightcheck_log
	echo 'Done. Check flightcheck_log for more details.'

	else
		echo 'Supported OS Not Detected'
	fi
fi
