#!/bin/bash

# Check distribution before installing packages
OS=`grep -Eiom 1 'CentOS|RedHat|ol|Ubuntu|Fedora|suse|amzn' /proc/version | head -1 | tr '[:upper:]' '[:lower:]'`

# Check for Systemd vs sysvinit
SYS=`ps -p 1 | grep -Eiom 1 'systemd|init'`

# Check for web server software
srv=`ls /etc | grep -Eiom 1 'Apache2|httpd|nginx|lighttpd'`

# Sets variables for dialog box
cmd=(dialog --separate-output --checklist "Select software to install:" 22 76 16)
options=(1 "Apache" off
         2 "Lighttpd" off
         3 "nginx" off
         4 "MySQL/MariaDB" off
         5 "MongoDB" off
         6 "PostgreSQL" off
         7 "Memcached" off
         8 "Redis" off
         9 "Varnish" off)

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
elif [ "$OS" == 'fedora' ]; then
  echo 'Fedora Detected'
elif [ "$OS" == 'suse' ]; then
  echo 'OpenSUSE Detected'
else
  echo 'Supported OS Not Detected'
  exit
fi

echo 'Make sure you run flightcheck.sh first'
sleep 5
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear

for choice in $choices
do

case $choice in

1)
  if [[ "$OS" == 'centos' || "$OS" == 'redhat' || "$OS" == 'ol' || "$OS" == 'amzn' ]]; then
    echo 'Installing Apache...'
    { # Installs base Apache stack
      yum -y install httpd httpd-tools php php-common php-gd php-xmlrpc php-xml openssl openssl-devel
      mkdir /etc/apache2/sites-available && /etc/apache2/sites-enabled

      # Starts Apache2 with Systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start httpd && systemctl enable httpd
        elif [ "$SYS" == 'init' ]; then
          service httpd start && chkconfig httpd on
        fi } &> ~/hydration_log

    echo 'Apache successfully installed with OpenSSL and PHP'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'fedora' ]; then
    echo 'Installing Apache...'
    { # Installs base Apache stack
      dnf -y install httpd php php-common php-gd php-xmlrpc php-xml openssl openssl-devel
      mkdir /etc/apache2/sites-available && /etc/apache2/sites-enabled

      # Starts Apache2 with Systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start httpd && systemctl enable httpd
        elif [ "$SYS" == 'init' ]; then
          service httpd start && chkconfig httpd on
        fi } &> ~/hydration_log

    echo 'Apache successfully installed with OpenSSL and PHP'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'ubuntu' ]; then
    echo 'Installing Apache...'
    { # Installs base Apache stack
        apt-get -y install apache2 apache2-utils php5 php5-common php5-gd php5-xmlrpc php5-xml openssl openssl-devel
        mkdir /etc/apache2/sites-available && /etc/apache2/sites-enabled

        # Starts Apache2 with Systemd or init script
          if [ "$SYS" == 'systemd' ]; then
            systemctl start apache2 && systemctl enable apache2
          elif [ "$SYS" == 'init' ]; then
            service apache2 start && chkconfig apache2 on
          fi } &> ~/hydration_log

    echo 'Apache successfully installed with OpenSSL and PHP'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'suse' ]; then
    echo 'Installing Apache...'
    { # Installs base Apache stack
      zypper -n ref && zypper -n in -R apache2 apache2-utils php5 apache2-mod_php5 openssl openssl-devel
      mkdir /etc/apache2/sites-available && /etc/apache2/sites-enabled

      # Enable PHP module for Apache
      a2enmod php5

      # Starts Apache2 with Systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start apache2 && systemctl enable apache2
        elif [ "$SYS" == 'init' ]; then
          service apache2 start && chkconfig apache2 on
        fi } &> ~/hydration_log

    echo 'Apache successfully installed with OpenSSL and PHP'
    echo 'Check hydration_log for more details'
  fi
;;

2)
  if [[ "$OS" == 'centos' || "$OS" == 'redhat' || "$OS" == 'ol' || "$OS" == 'amzn' ]]; then
    echo 'Installing Lighttpd...'
    { # Installs Lighttpd
      yum -y install lighttpd httpd-utils php php-common php-gd php-xmlrpc php-xml openssl openssl-devel
      mkdir /etc/lighttpd/sites-available && /etc/lighttpd/sites-enabled

      # Starts Lighttpd with Systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start lighttpd && systemctl enable lighttpd
        elif [ "$SYS" == 'init' ]; then
          service lighttpd start && chkconfig lighttpd on
        fi } &> ~/hydration_log

    echo 'Lighttpd successfully installed with OpenSSL and PHP'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'fedora' ]; then
    echo 'Installing Lighttpd...'
    { # Installs Lighttpd
      dnf -y install lighttpd php-common php-gd php-xmlrpc php-xml openssl openssl-devel
      mkdir /etc/lighttpd/sites-available && /etc/lighttpd/sites-enabled

      # Fix common issues with Lighttpd and IPv6
      sed s/"server.use-ipv6 = \"enable\""/"server.use-ipv6 = \"disable\""/ /etc/lighttpd/lighttpd.conf -i
      sed s/"#server.max-fds = 2048"/"server.max-fds = 2048"/ /etc/lighttpd/lighttpd.conf -i

      # Starts Lighttpd with Systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start lighttpd && systemctl enable lighttpd
        elif [ "$SYS" == 'init' ]; then
          service lighttpd start && chkconfig lighttpd on
        fi } &> ~/hydration_log

    echo 'Lighttpd successfully installed with OpenSSL and PHP'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'ubuntu' ]; then
    echo 'Installing Lighttpd...'
    { # Installs lighttpd
      apt-get -y install lighttpd apache2-utils php5 php5-common php5-gd php5-xmlrpc php5-xml php5-cgi openssl openssl-devel
      mkdir /etc/lighttpd/sites-available && /etc/lighttpd/sites-enabled

      # Enables PHP5-CGI for use with Lighttpd
      lighttpd-enable-mod fastcgi fastcgi-php

      # Starts Lighttpd with Systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start lighttpd && systemctl enable lighttpd
        elif [ "$SYS" == 'init' ]; then
          service lighttpd start && chkconfig lighttpd on
          fi } &> ~/hydration_log

    echo 'Lighttpd successfully installed with OpenSSL and PHP5-CGI'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'suse' ]; then
    echo 'Installing Lighttpd...'
    { # Installs Lighttpd
      zypper -n ref && zypper -n in -R lighttpd apache2-utils php5 php5-fpm openssl openssl-devel
      mkdir /etc/lighttpd/sites-available && /etc/lighttpd/sites-enabled

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
        fi } &> ~/hydration_log

    echo 'Lighttpd successfully installed with OpenSSL and PHP-FPM'
    echo 'Check hydration_log for more details'
  fi
;;

3)
  if [[ "$OS" == 'centos' || "$OS" == 'redhat' || "$OS" == 'ol' || "$OS" == 'amzn' ]]; then
    echo 'Installing nginx...'
    { # Installs base nginx stack
      yum -y install nginx httpd-tools php php-common php-gd php-xmlrpc php-xml php-fpm openssl openssl-devel
      mkdir /etc/nginx/sites-available && /etc/nginx/sites-enabled
      # Starts nginx and php-fpm with Systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start nginx && systemctl enable nginx
          systemctl start php-fpm && systemctl enable php-fpm
        elif [ "$SYS" == 'init' ]; then
          service nginx start && chkconfig nginx on
          service php-fpm start && chkconfig nginx on
        fi } &> ~/hydration_log

    echo 'nginx successfully installed with OpenSSL and PHP-FPM'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'fedora' ]; then
    echo 'Instaling nginx...'
    { # Installs base nginx stack
      dnf -y --enablerepo=remi install nginx php php-common php-fpm php-gd php-xmlrpc php-xml openssl openssl-devel
      mkdir /etc/nginx/sites-available && mkdir /etc/nginx/sites-enabled
      echo "include /etc/nginx/sites-enabled/*;" >> /etc/nginx/nginx.conf
      # Starts nginx and php-fpm with Systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start nginx && systemctl enable nginx
          systemctl start php-fpm && systemctl enable php-fpm
        elif [ "$SYS" == 'init' ]; then
          service nginx start && chkconfig nginx on
          service php-fpm start && chkconfig nginx on
        fi } &> ~/hydration_log

    echo 'nginx successfully installed with OpenSSL and PHP-FPM'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'ubuntu' ]; then
    echo 'Installing nginx...'
    { # Installs base nginx stack
      apt-get -y install nginx apache2-utils php5 php5-common php5-gd php5-xmlrpc php5-xml php5-fpm openssl openssl-devel
      mkdir /etc/nginx/sites-available && /etc/nginx/sites-enabled
      # Starts nginx and php-fpm with Systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start nginx && systemctl enable nginx
          systemctl start php5-fpm && systemctl enable php5-fpm
        elif [ "$SYS" == 'init' ]; then
          service nginx start && chkconfig nginx on
          service php5-fpm start && chkconfig nginx on
        fi } &> ~/hydration_log

    echo 'nginx successfully installed with OpenSSL and PHP-FPM'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'suse' ]; then
    echo 'Installing nginx...'
    { # Installs base nginx stack
      zypper -n ref && zypper -n in -R nginx-1.0 php5 php5-fpm openssl openssl-devel
      mkdir /etc/nginx/sites-available && /etc/nginx/sites-enabled

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
        fi } &> ~/hydration_log

    echo 'nginx successfully installed with OpenSSL and PHP-FPM'
    echo 'Check hydration_log for more details'
  fi
;;

4)
  if [ "$OS" == 'centos' || "$OS" == 'redhat' || "$OS" == 'ol' || "$OS" == 'amzn' ]; then
    echo 'Installing MySQL/MariaDB...'
    { # Installs MySQL server and PHP Driver
      yum -y install mysql mysql-server php-mysql

      # Starts MariaDB/MySQL with Systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start mysql && systemctl enable mysql
        elif [ "$SYS" == 'init' ]; then
          service mysql start && chkconfig mysql on
        fi } &> ~/hydration_log

    echo 'MySQL successfully installed'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'fedora' ]; then
    echo 'Installing MySQL/MariaDB...'
    { # Installs MySQL server and PHP Driver
      dnf -y install mysql mysql-server php-mysql

      # Starts MariaDB/MySQL with Systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start mariadb && systemctl enable mariadb
        elif [ "$SYS" == 'init' ]; then
          service mariadb start && chkconfig mariadb on
        fi } &> ~/hydration_log

    echo 'MySQL successfully installed'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'ubuntu' ]; then
    echo 'Installing MySQL/MariaDB...'
    { # Installs MySQL server and PHP Driver
      apt-get -y install mysql mysql-server php5-mysql

      # Starts MariaDB/MySQL with Sytemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start mysql && systemctl enable mysql
        elif [ "$SYS" == 'init' ]; then
          service mysql start && chkconfig mysql on
        fi } &> ~/hydration_log
    echo 'MySQL successfully installed'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'suse' ]; then
    echo 'Installing MySQL/MariaDB...'
    { # Installs MySQL server and PHP Driver
      zypper -n ref && zypper -n in -R mariadb mariadb-tools php5-mysql
      # Starts MariaDB/MySQL with Systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start mysql && systemctl enable mysql
        elif [ "$SYS" == 'init' ]; then
          service mysql start && chkconfig mysql on
        fi } &> ~/hydration_log
    echo 'MySQL successfully installed'
    echo 'Check hydration_log for more details'
  fi
;;

5)
  if [[ "$OS" == 'centos' || "$OS" == 'redhat' || "$OS" == 'ol' || "$OS" == 'fedora' || "$OS" == 'amzn' ]]; then
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
      yum -y install mongodb-org mongodb-org-server php-pecl

      # Installs PHP MongoDB Driver
      pecl install mongodb
      echo "extension=mongodb.so" >> `php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||"`

      # Starts MongoDB with Systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start mongod && systemctl enable mongodb-org
        elif [ "$SYS" == 'init' ]; then
          service mongod start && chkconfig mongod on
        fi } &> ~/hydration_log

    echo 'MongoDB successfuly installed'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'ubuntu' ]; then
		echo 'Installing MongoDB...'
		{ # Import MongoDB apt-key
		  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10

      # Add MongoDB apt repo
		  echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | tee /etc/apt/sources.list.d/mongodb.list

		  # Update apt cache and install MongoDB
		  apt-get update && apt-get -y install mongodb-org php5-pecl

		  # Installs PHP MongoDB Driver
		  pecl install mongodb
		  echo "extension=mongodb.so" >> `php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||"`

		  # Start MongoDB with Systemd or init script
		      if [ "$SYS" == 'systemd' ]; then
			       systemctl start mongod && systemctl enable mongod
		      elif [ "$SYS" == 'init' ]; then
			       service mongod start && chkconfig mongod on
		      fi } &> ~/hydration_log

    echo 'MongoDB successfully installed'
	  echo 'Check hydration_log for more details'

  elif [ "$OS" == 'suse' ]; then
  	echo 'Installing MongoDB...'
  	{ # Add MongoDB repo
  		zypper -n addrepo --no-gpgcheck https://repo.mongodb.org/zypper/suse/$(sed -rn 's/VERSION=.*([0-9]{2}).*/\1/p' /etc/os-release)/mongodb-org/3.2/x86_64/ mongodb

  		# Refresh zypper cache and install MongoDB
  		zypper -n ref && zypper -n in -R mongodb-org php-pecl

  		# Installs PHP MongoDB Driver
  		pecl install mongodb
  		echo "extension=mongodb.so" >> `php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||"`

  		# Start MongoDB with Systemd or init script
  		  if [ "$SYS" == 'systemd' ]; then
  			   systemctl start mongod && systemctl enable mongod
  		  elif [ "$SYS" == 'init' ]; then
  			   service mongod start && chkconfig mongod on
  		  fi } &> ~/hydration_log

  	echo 'MongoDB successfully installed'
  	echo 'Check hyration_log for more details'
  fi
;;

6)
  if [[ "$OS" == 'centos' || "$OS" == 'redhat' || "$OS" == 'ol' || "$OS" == 'amzn' ]]; then
    echo 'Installing PostgreSQL (PGSQL)...'
    { # Installs PostgreSQL/PGSQL and PHP Driver
      yum -y install postgresql-server postgresql-contrib postgresql-libs php-pgsql

      # Initializes base DB
      postgresql-setup init db

      # Changes Host-Based Auth file from identity to passwd auth
      sed -i -e 's/ident/md5/g' /var/lib/pgsql/data/pg_hba.conf

      # Starts PGSQL with Systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start postgresql && systemctl enable postgresql
        elif [ "$SYS" == 'init' ]; then
          service postgresql start && chkconfig postgresql on
        fi } &> ~/hydration_log

    echo 'PostgreSQL successfully installed'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'fedora' ]; then
    echo 'Installing PostgreSQL (PGSQL)...'
    { # Installs PostgreSQL/PGSQL and PHP Driver
      dnf -y install postgresql postgresql-server postgresql-libs php-pgsql

      # Initializes base DB
      postgresql-setup init db

      # Starts PGSQL with Systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start postgresql && systemctl enable postgresql
        elif [ "$SYS" == 'init' ]; then
          service postgresql start && chkconfig postgresql on
        fi } &> ~/hydration_log

    echo 'PostgreSQL successfully installed'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'ubuntu' ]; then
    echo 'Installing PostgreSQL (PGSQL)...'
    { # Installs PostgreSQL/PGSQL and PHP Driver
      apt-get update && apt-get -y install postgresql postgresql-contrib postgresql-libs php5-pgsql

      # Starts PGSQL with systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start postgresql && systemctl enable postgresql
        elif [ "$SYS" == 'init' ]; then
          service postgresql start && chkconfig postgresql on
        fi } &> ~/hydration_log

    echo 'PostgreSQL successfully installed'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'suse' ]; then
    echo 'Installing PostgreSQL (PGSQL)...'
    { # Installs PostgreSQL/PGSQL
      zypper -n addrepo -t YUM http://packages.2ndquadrant.com/postgresql-z-suse/zypper/sles-11sp3-s390x pg
      zypper -n refresh && zypper -n in -R postgresql-server postgresql-libs php-pgsql

      # Initializes DB
      service postgresql initdb

      # Starts PGSQL with systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start postgresql && systemctl enable postgresql
        elif [ "$SYS" == 'init' ]; then
          service posgresql start && chkconfig postgresql on
        fi } &> ~/hydration_log

    echo 'PosgreSQL successfully installed'
    echo 'Check hydration_log for more details'
  fi
;;

7)
  if [[ "$OS" == 'centos' || "$OS" == 'redhat' || "$OS" == 'ol' || "$OS" == 'fedora' || "$OS" == 'amzn' ]]; then
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
        fi } &> ~/hydration_log

    echo "Memcached successfully installed and $srv restarted"
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'fedora' ]; then
    echo 'Installing Memcacehd...'
    { # Installs Memcached and Memcached PHP module
      dnf -y install memcached php-pecl-memcacehd

      # Starts Memcached with systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start memcached && systemctl enable memcached
          systemctl restart $srv
        elif [ "$SYS" == 'init' ]; then
          service memcached start && chkconfig memcached on
          service $srv restart
        fi } &> ~/hydration_log

    echo "Memcached successfully installed and $srv restarted"
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'ubuntu' ]; then
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
        fi } &> ~/hydration_log

    echo "Memcached successfully installed and $srv restarted"
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'suse' ]; then
    echo 'Installing Memcached...'
    { # Installs Memcached and Memcached PHP module
      yast2 -i memcached
      zypper -n refresh && zypper -n in -R php-pecl
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
        fi } &> ~/hydration_log

    echo "Memcached successfully installed and $srv restarted"
    echo 'Check hydration_log for more details'
  fi
;;

8)
  if [ "$OS" == 'centos' || "$OS" == 'redhat' || "$OS" == 'ol' || "$OS" == 'amzn' || "$OS" == 'fedora' ]; then
    echo 'Installing Redis...'
    { # Grabs tarball and extracts to /tmp
      curl -sSL http://download.redis.io/releases/redis-stable.tar.gz -o /tmp/redis.tar.gz
      tar xzf redis.tar.gz

      # Creates make file and installs Redis
      make -C /tmp/redis-stable
      make -C /tmp/redis-stable install
      echo -n | /tmp/redis/utils/install_server.sh
      rm -rf /tmp/redis*

      # Config changes
      sysctl vm.overcommit_memory=1
      sed -i -e 's/# bind 127.0.0.1/bind 127.0.0.1/g' /etc/redis/6379.conf

      # Starts Redis with systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start redis_6379 && systemctl enable redis_6379
        elif [ "$SYS" == 'init' ]; then
          service redis_6379 start && chkconfig redis_6379 on
        fi } &> ~/hydration_log

    echo 'Redis successfully installed'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'ubuntu' ]; then
    echo 'Installing Redis...'
    { # Grabs tarball and extracts to /tmp
      curl -sSL http://download.redis.io/releases/redis-stable.tar.gz -o /tmp/redis.tar.gz
      tar xzf redis.tar.gz

      # Creates make file and installs Redis
      make -C /tmp/redis-stable
      make -C /tmp/redis-stable install
      echo -n | /tmp/redis/utils/install_server.sh
      rm -rf /tmp/redis*

      # Config changes
      sysctl vm.overcommit_memory=1
      sed -i -e 's/# bind 127.0.0.1/bind 127.0.0.1/g' /etc/redis/6379.conf

      # Starts Redis with systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start redis_6379 && systemctl enable redis_6379
        elif [ "$SYS" == 'init' ]; then
          service redis_6379 start && chkconfig redis_6379 on
        fi } &> ~/hydration_log

    echo 'Redis successfully installed'
    echo 'Check hydration_log for more details'

  elif [ "$OS" == 'suse' ]; then
    echo 'Installing Redis...'
    { # Grabs tarball and extracts to /tmp
      curl -sSL http://download.redis.io/releases/redis-stable.tar.gz -o /tmp/redis.tar.gz
      tar xzf redis.tar.gz

      # Creates make file and installs Redis
      make -C /tmp/redis-stable
      make -C /tmp/redis-stable install
      echo -n | /tmp/redis/utils/install_server.sh
      rm -rf /tmp/redis*

      # Config changes
      sysctl vm.overcommit_memory=1
      sed -i -e 's/# bind 127.0.0.1/bind 127.0.0.1/g' /etc/redis/6379.conf

      # Starts Redis with systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start redis_6379 && systemctl enable redis_6379
        elif [ "$SYS" == 'init' ]; then
          service redis_6379 start && chkconfig redis_6379 on
        fi } &> ~/hydration_log

    echo 'Redis successfully installed'
    echo 'Check hydration_log for more details'
  fi
;;

9)
  if [[ "$OS" == 'centos' || "$OS" == 'redhat' || "$OS" == 'ol' || "$OS" == 'fedora' || "$OS" == 'amzn' ]]; then
    echo 'Installing Varnish...'
    { # Install Varnish
      yum -y install varnish

      # Start Varnish with systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start varnish && systemctl enable varnish
        elif [ "$SYS" == 'init' ]; then
          service varnish start && chkconfig varnish on
        fi } &> ~/hydration_log

    echo 'Varnish successfully installed'
    echo "Modify the vhosts for your webserver $srv and check hydration_log for more details"

  elif [ "$OS" == 'fedora' ]; then
    echo 'Installing Varnish...'
    { # Install Varnish
      dnf -y install varnish

      # Starts Varnish with systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start varnish && systemctl enable varnish
        elif [ "$SYS" == 'init' ]; then
          service varnish start && chkconfig varnish on
        fi } &> ~/hydration_log

    echo 'Varnish successfully installed'
    echo "Modify the vhosts for your webserver $srv and check hydration_log for more details"

  elif [ "$OS" == 'ubuntu' ]; then
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
        fi } &> ~/hydration_log

    echo 'Varnish successfully installed'
    echo "Modify the vhosts for your webserver $srv and check hydration_log for more details"

  elif [ "$OS" == 'suse' ]; then
    echo 'Installing Varnish...'
    { # Add repo and install Varnish
      zypper -n addrepo http://download.OpenSUSE.org/repositories/server:http/OpenSUSE_Tumbleweed/server:http.repo
      zypper -n refresh && zypper -n in -R varnish

      # Start Varnish with systemd or init script
        if [ "$SYS" == 'systemd' ]; then
          systemctl start varnish && systemctl enable varnish
        elif [ "$SYS" == 'init' ]; then
          service varnish start && chkconfig varnish on
        fi } &> ~/hydration_log
    echo 'Varnish successfully installed'
    echo "Modify the vhosts for your webserver $srv and check hydration_log for more details"
  fi
;;
