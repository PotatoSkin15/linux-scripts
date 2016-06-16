#!/bin/bash

clear

# Check distribution before installing packages
OS=`grep -Eiom 1 'CentOS|RedHat|euk|Ubuntu|Fedora|SUSE|amzn' /proc/version`

# Check for Systemd vs sysvinit
SYS=`ps -p 1 | grep -Eiom 1 'systemd|init'`

if [ "$USER" != 'root' ]; then
		echo 'WARNING! This script should be run as root'
		echo 'Please enter sudo su and run the script again'
else
echo 'Make sure you run flightcheck.sh first'
sleep 5
cat << EOF
Select your action:
1) Install web server (Apache, Lighttpd, nginx)
2) Install DB server (MySQL/MariaDB, MongoDB, PGSQL)
3) Install performance tools (Memcache, Varnish)
EOF

printf 'Selection [1|2|3]:'
read -r task

case $task in
1)
clear
cat << EOF
Select webserver:
a) Apache
l) Lighttpd
n) nginx
EOF

printf 'Selection [a|l|n]:'
read -r webserver

case $webserver in
	a|A)
		if [ "$OS" == 'centos' -a 'redhat' -a 'euk' -a 'fedora' -a 'amzn' ]; then
			echo 'RHEL-Based OS Detected'
			echo 'Installing Apache...'
			{ # Installs base Apache stack
			yum -y install httpd httpd-tools php php-common php-gd php-xmlrpc php-xml openssl openssl-devel
			# Starts Apache2 with Systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start httpd && systemctl enable httpd
				elif [ "$SYS" == 'init' ]; then
					service httpd start && chkconfig httpd on
				fi } >> ~/hydration_log
			echo 'Apache successfully installed with OpenSSL and PHP'
			echo 'Check hydration_log for more details'

		elif [ "$OS" == 'ubuntu' ]; then
			echo 'Ubuntu OS Detected'
			echo 'Installing Apache...'
			{ # Installs base Apache stack
			apt-get -y install apache2 apache2-utils php5 php5-common php5-gd php5-xmlrpc php5-xml openssl openssl-devel
			# Starts Apache2 with Systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start apache2 && systemctl enable apache2
				elif [ "$SYS" == 'init' ]; then
					service apache2 start && chkconfig apache2 on
				fi } >> ~/hydration_log
			echo 'Apache successfully installed with OpenSSL and PHP'
			echo 'Check hydration_log for more details'

		elif [ "$OS" == 'SUSE' ]; then
			echo 'OpenSUSE OS Detected'
			echo 'Installing Apache...'
			{ #Installs base Apache stack
			zypper -n in -R apache2 apache2-utils php5 apache2-mod_php5 openssl openssl-devel
			# Enable PHP module for Apache
			a2enmod php5
			# Starts Apache2 with Systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start apache2 && systemctl enable apache2
				elif [ "$SYS" == 'init' ]; then
					service apache2 start && chkconfig apache2 on
				fi } >> ~/hydration_log
			echo 'Apache successfully installed with OpenSSL and PHP'
			echo 'Check hydration_log for more details'
		fi
	;;

	l|L)
		if [ "$OS" == 'centos' -a 'redhat' -a 'euk' -a 'fedora' -a 'amzn' ]; then
			echo 'RHEL-Based OS Detected'
			echo 'Installing Lighttpd...'
			{ # Installs Lighttpd
			yum -y install lighttpd httpd-utils php php-common php-gd php-xmlrpc php-xml openssl openssl-devel
			# Starts Lighttpd with Systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start lighttpd && systemctl enable lighttpd
				elif [ "$SYS" == 'init' ]; then
					service lighttpd start && chkconfig lighttpd on
				fi } >> ~/hydration_log
		echo 'Lighttpd successfully installed with OpenSSL and PHP'
		echo 'Check hydration_log for more details'

		elif [ "$OS" == 'ubuntu' ]; then
			echo 'Ubuntu OS Detected'
			echo 'Installing Lighttpd'
			{ # Installs lighttpd
			apt-get -y install lighttpd apache2-utils php5 php5-common php5-gd php5-xmlrpc php5-xml php5-cgi openssl openssl-devel
			# Enables PHP5-CGI for use with Lighttpd
			lighttpd-enable-mod fastcgi fastcgi-php
			# Starts Lighttpd with Systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start lighttpd && systemctl enable lighttpd
				elif [ "$SYS" == 'init' ]; then
					service lighttpd start && chkconfig lighttpd on
				fi } >> ~/hydration_log
		echo 'Lighttpd successfully installed with OpenSSL and PHP5-CGI'
		echo 'Check hydration_log for more details'

		elif [ "$OS" == 'SUSE' ]; then
			echo 'OpenSUSE OS Detected'
			echo 'Installing Lighttpd...'
			{ # Installs Lighttpd
			zypper -n -R in lighttpd apache2-utils php5 php5-fpm openssl openssl-devel
			# Rename PHP-FPM Directory
			mv /etc/php5/fpm/php-fpm.conf.default /etc/php5/fpm/php-fpm.conf
			cp /etc/php5/cli/php.ini /etc/php5/fpm/
			sed -i -e 's/cgi.fix_pathinfo=0/cgi.fix_pathinfo=1/g'
			# Starts Lighttpd and PHP-FPM with Systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start lighttpd && systemctl enable lighttpd
					systemctl start php-fpm && systemctl enable php-fpm
				elif [ "$SYS" == 'init' ]; then
					service lighttpd start && chkconfig lighttpd on
					service php-fpm start && chkconfig php-fpm on
				fi } >> ~/hydration_log
		echo 'Lighttpd successfully installed with OpenSSL and PHP-FPM'
		echo 'Check hydration_log for more details'
		fi
	;;

	n|N)
		if [ "$OS" == 'centos' -a 'redhat' -a 'euk' -a 'fedora' -a 'amzn' ]; then
			echo 'RHEL-Based OS Detected'
			echo 'Installing nginx...'
			{ # Installs base nginx stack
			yum -y install nginx httpd-tools php php-common php-gd php-xmlrpc php-xml php-fpm openssl openssl-devel
			# Starts nginx and php-fpm with Systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start nginx && systemctl enable nginx
					systemctl start php-fpm && systemctl enable php-fpm
				elif [ "$SYS" == 'init' ]; then
					service nginx start && chkconfig nginx on
					service php-fpm start && chkconfig nginx on
				fi } >> ~/hydration_log
		echo 'nginx successfully installed with OpenSSL and PHP-FPM'
		echo 'Check hydration_log for more details'

		elif [ "$OS" == 'ubuntu' ]; then
			echo 'Ubuntu OS Detected'
			echo 'Installing nginx...'
			{ # Installs base nginx stack
			apt-get -y install nginx apache2-utils php5 php5-common php5-gd php5-xmlrpc php5-xml php5-fpm openssl openssl-devel
			# Starts nginx and php-fpm with Systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start nginx && systemctl enable nginx
					systemctl start php5-fpm && systemctl enable php5-fpm
				elif [ "$SYS" == 'init' ]; then
					service nginx start && chkconfig nginx on
					service php5-fpm start && chkconfig nginx on
				fi } >> ~/hydration_log
		echo 'nginx successfully installed with OpenSSL and PHP-FPM'
		echo 'Check hydration_log for more details'

		elif [ "$OS" == 'SUSE' ]; then
			echo 'OpenSUSE OS Detected'
			echo 'Installing nginx...'
			{ # Installs base nginx stack
			zypper -n -R in nginx-1.0 php5 php5-fpm openssl openssl-devel
			# Rename PHP-FPM Directory
			mv /etc/php5/fpm/php-fpm.conf.default /etc/php5/fpm/php-fpm.conf
			cp /etc/php5/cli/php.ini /etc/php5/fpm/
			sed -i -e 's/cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g'
			# Starts nginx and php-fpm with Systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start nginx && systemctl enable nginx
					systemctl start php-fpm && systemctl enable php-fpm
				elif [ "$SYS" == 'init' ]; then
					service nginx start && chkconfig nginx on
					service php-fpm start && chkconfig php-fpm on
				fi } >> ~/hydration_log
		echo 'nginx successfully installed with OpenSSL and PHP-FPM'
		echo 'Check hydration_log for more details'
		fi
	;;

	*)
		echo 'Please enter a valid option'
	;;
	esac
;;

2)
clear
cat << EOF
Select database server:
m) MySQL/MariaDB
o) MongoDB
p) PostgreSQL
EOF

printf 'Selection [m|o|p]:'
read -r dbserver

case $dbserver in
	m|M)
		if [ "$OS" == 'centos' -a 'redhat' -a 'euk' -a 'fedora' -a 'amzn' ]; then
			echo 'RHEL-Based OS Detected'
			echo 'Installing MySQL/MariaDB...'
			{ # Installs MySQL server
			yum -y install mysql mysql-server php-mysql
			# Starts MariaDB/MySQL with Systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start mysql && systemctl enable mysql
				elif [ "$SYS" == 'init' ]; then
					service mysql start && chkconfig mysql on
				fi } >> ~/hydration_log
		echo 'MySQL successfully installed'
		echo 'Check hydration_log for more details'

		elif [ "$OS" == 'ubuntu' ]; then
			echo 'Ubuntu OS Detected'
			echo 'Installing MySQL/MariaDB...'
			{ # Installs MySQL server
			apt-get -y install mysql mysql-server php5-mysql
			# Starts MariaDB/MySQL with Sytemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start mysql && systemctl enable mysql
				elif [ "$SYS" == 'init' ]; then
					service mysql start && chkconfig mysql on
				fi } >> ~/hydration_log
		echo 'MySQL successfully installed'
		echo 'Check hydration_log for more details'

		elif [ "$OS" == 'SUSE' ]; then
			echo 'OpenSUSE OS Detected'
			echo 'Installing MySQL/MariaDB...'
			{ # Installs MySQL/MariaDB server
			zypper -n -R in mariadb mariadb-tools php5-mysql
			# Starts MariaDB/MySQL with Systemd or init script
			if [ "$SYS" == 'systemd' ]; then
				systemctl start mysql && systemctl enable mysql
			elif [ "$SYS" == 'init' ]; then
				service mysql start && chkconfig mysql on
			fi } >> ~/hydration_log
		echo 'MySQL successfully installed'
		echo 'Check hydration_log for more details'
		fi
	;;

	o|O)
		if [ "$OS" == 'centos' -a 'redhat' -a 'euk' -a 'fedora' -a 'amzn' ]; then
			echo 'RHEL-Based OS Detected'
			echo 'Installing MongoDB...'
			{ # Installs MongoDB Repo and updates Yum
			echo "
			[mongodb]
			name=MongoDB Repository
			baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.2/x86_64/
			gpgcheck=1
			enabled=1
			gpgkey=https://www.mongodb.org/static/pgp/server-3.2.asc" >> /etc/yum.repos.d/mongodb.repos

			# Refresh Yum cache and install MongoDB
 			yum -y install mongodb-org mongodb-org-server

			# Starts MongoDB with Systemd or init script
			if [ "$SYS" == 'systemd' ]; then
				systemctl start mongod && systemctl enable mongodb-org
			elif [ "$SYS" == 'init' ]; then
				service mongod start && chkconfig mongod on
			fi } >> ~/hydration_log
		echo 'MongoDB successfuly installed'
		echo 'Check hydration_log for more details'

	elif [ "$OS" == 'ubuntu' ]; then
		echo 'Ubuntu OS Detected'
		echo 'Installing MongoDB...'
		{ # Import MongoDB apt-key
		apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
		# Add MongoDB apt repo
		echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | tee /etc/apt/sources.list.d/mongodb.list

		# Update apt cache and install MongoDB
		apt-get update && apt-get -y install mongodb-org

		# Start MongoDB with Systemd or init script
		if [ "$SYS" == 'systemd' ]; then
			systemctl start mongod && systemctl enable mongod
		elif [ "$SYS" == 'init' ]; then
			service mongod start && chkconfig mongod on
		fi } >> ~/hydration_log
	echo 'MongoDB successfully installed'
	echo 'Check hydration_log for more details'

	elif [ "$OS" == 'SUSE' ]; then
		echo 'OpenSUSE OS Detected'
		echo 'Installing MongoDB...'
		{ # Add MongoDB repo
		zypper -n addrepo --no-gpgcheck https://repo.mongodb.org/zypper/suse/$(sed -rn 's/VERSION=.*([0-9]{2}).*/\1/p' /etc/os-release)/mongodb-org/3.2/x86_64/ mongodb

		# Refresh zypper cache and install MongoDB
		zypper -n ref && zypper -n in mongodb-org

		# Start MongoDB with Systemd or init script
		if [ "$SYS" == 'systemd' ]; then
			systemctl start mongod && systemctl enable mongod
		elif [ "$SYS" == 'init' ]; then
			service mongod start && chkconfig mongod on
		fi } >> ~/hydration_log
	echo 'MongoDB successfully installed'
	echo 'Check hyration_log for more details'
	fi
	;;

	p|P)
		if [ "$OS" == 'centos' -a 'redhat' -a 'euk' -a 'fedora' -a 'amzn' ]; then
			echo 'RHEL-Based OS Detected'
			echo 'Installing PostgreSQL (PGSQL)...'
			{ # Installs PostgreSQL/PGSQL
			yum -y install postgresql-server postgresql-contrib
			# Initializes base DB
			postgresql-setup init db
			# Changes Host-Based Auth file from identity to passwd auth
			sed -i -e 's/ident/md5/g' /var/lib/pgsql/data/pg_hba.conf
			# Starts PGSQL with Systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start postgresql && systemctl enable postgresql
				elif [ "$SYS" == 'init' ]; then
					service postgresql start && chkconfig postgresql on
				fi } >> ~/hydration_log
		echo 'PostgreSQL successfully installed'
		echo 'Check hydration_log for more details'

		elif [ "$OS" == 'ubuntu' ]; then
			echo 'Ubuntu OS Detected'
			echo 'Installing PostgreSQL (PGSQL)...'
			{ # Installs PostgreSQL/PGSQL
			apt-get update && apt-get -y install postgresql postgresql-contrib
			# Starts PGSQL with systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start postgresql && systemctl enable postgresql
				elif [ "$SYS" == 'init' ]; then
					service postgresql start && chkconfig postgresql on
				fi } >> ~/hydration_log
		echo 'PostgreSQL successfully installed'
		echo 'Check hydration_log for more details'

		elif [ "$OS" == 'SUSE' ]; then
			echo 'OpenSUSE OS Detected'
			echo 'Installing PostgreSQL (PGSQL)...'
			{ # Installs PostgreSQL/PGSQL
			zypper -n addrepo -t YUM http://packages.2ndquadrant.com/postgresql-z-suse/zypper/sles-11sp3-s390x pg
			zypper -n refresh
			zypper -n -R in postgresql-server
			# Initializes DB
			service postgresql initdb
			# Starts PGSQL with systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start postgresql && systemctl enable postgresql
				elif [ "$SYS" == 'init' ]; then
					service posgresql start && chkconfig postgresql on
				fi } >> ~/hydration_log
		echo 'PosgreSQL successfully installed'
		echo 'Check hydration_log for more details'
		fi
	;;

	*)
		echo 'Please enter a valid option'
	;;
	esac
;;

3)
# Check for web server software
srv=`ls /etc | grep -Eiom 1 'Apache2|httpd|nginx|lighttpd'`

clear
cat << EOF
Select tool to install:
m) Memcached
v) Varnish
EOF

printf 'Selection [m|v]:'
read -r performance

case $performance in
	m|M)
		if [ "$OS" == 'centos' -a 'RedHat' -a 'euk' -a 'fedora' -a 'amzn' ]; then
			echo 'RHEL-Based OS Detected'
			echo 'Installing Memcached...'
			{ # Installs Memcached and Memcached PHP module
			yum -y install libevent libevent-devel memcached php-pecl-memcached
			# Starts Memcahced with systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start memcached && systemctl enable memcached
					systemctl restart $srv
				elif [ "$SYS" == 'init' ]; then
					service memcached start && chkconfig memcached on
					service $srv restart
				fi } >> ~/hydration_log
		echo "Memcached successfully installed and $srv restarted"
		echo 'Check hydration_log for more details'

		elif [ "$OS" == 'ubuntu' ]; then
			echo 'Ubuntu OS Detected'
			echo 'Installing Memcached...'
			{ # Installs Memcached and Memcached PHP module
			apt-get update && apt-get -y install memcached php5-memcached
			# Starts Memcached with systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start memcached && systemctl enable memcached
					systemctl restart $srv
				elif [ "$SYS" == 'init' ]; then
					service memcached start && chkconfig memcached on
					service $srv restart
				fi } >> ~/hydration_log
		echo "Memcached successfully installed and $srv restarted"
		echo 'Check hydration_log for more details'

		elif [ "$OS" == 'SUSE' ]; then
			echo 'OpenSUSE OS Detected'
			echo 'Installing Memcached...'
			{ # Installs Memcached and Memcached PHP module
			yast2 -i memcached
			zypper -n refresh && zypper -n -R in php-pecl
			pecl install memcache
			# Add Memcached module to load with PHP
			echo 'extension=memcache.so' >> /etc/php5/conf.d/memcache.ini
			# Starts Memcached with systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start memcached && systemctl enable memcached
					systemctl restart $srv
				elif [ "$SYS" == 'init' ]; then
					service memcached start && chkconfig memcached on
					service $srv restart
				fi } >> ~/hydration_log
		echo "Memcached successfully installed and $srv restarted"
		echo 'Check hydration_log for more details'
		fi
	;;

	v|V)
		if [ "$OS" == 'centos' -a 'RedHat' -a 'euk' -a 'fedora' -a 'amzn' ]; then
			echo 'RHEL-Based OS Detected'
			echo 'Installing Varnish...'
			{ # Install Varnish
			yum -y install varnish
			# Start Varnish with systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start varnish && systemctl enable varnish
				elif [ "$SYS" == 'init' ]; then
					service varnish start && chkconfig varnish on
				fi } >> ~/hydration_log
		echo 'Varnish successfully installed'
		echo "Modify the vhosts for your webserver $srv and check hydration_log for more details"

		elif [ "$OS" == 'ubuntu' ]; then
			echo 'Ubuntu OS Detected'
			echo 'Installing Varnish...'
			{ # Add Varnish repo and GPG key
			apt-get -y install apt-transport-https
			curl https://repo.varnish-cache.org/GPG-key.txt | apt-key add -
			echo "deb https://repo.varnish-cache.org/ubuntu/ trusty varnish-4.1" >> /etc/apt/sources.list.d/varnish-cache.list
			# Install Varnish
			apt-get update && apt-get -y install varnish
			# Start Varnish with systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start varnish && systemctl enable varnish
				elif [ "$SYS" == 'init' ]; then
					service varnish start && chkconfig varnish on
				fi } >> ~/hydration_log
		echo 'Varnish successfully installed'
		echo "Modify the vhosts for your webserver $srv and check hydration_log for more details"

		elif [ "$OS" == 'SUSE' ]; then
			echo 'OpenSUSE OS Detected'
			echo 'Installing Varnish...'
			{ # Add repo and install Varnish
			zypper -n addrepo http://download.opensuse.org/repositories/server:http/openSUSE_Tumbleweed/server:http.repo
			zypper -n refresh && zypper -n install varnish
			# Start Varnish with systemd or init script
				if [ "$SYS" == 'systemd' ]; then
					systemctl start varnish && systemctl enable varnish
				elif [ "$SYS" == 'init' ]; then
					service varnish start && chkconfig varnish on
				fi } >> ~/hydration_log
		echo 'Varnish successfully installed'
		echo "Modify the vhosts for your webserver $srv and check hydration_log for more details"
		fi
	;;

	*)
		echo 'Please select a valid option'
	;;
	esac
;;

*)
	echo 'Please select a valid option'
;;
esac
fi
