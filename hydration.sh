#!/bin/bash

clear

# Check distribution before installing packages
OS=`grep -Eiom 1 'CentOS|RedHat|Ubuntu|Fedora' /proc/version`

# Check for Systemd vs sysvinit
SYS=`ps -p 1 -o cmd h`

if [ "$USER" != "root" ]; then
		echo 'WARNING! This script should be run as root'
		echo 'Please enter sudo su and run the script again'
else
  echo "Make sure you run flightcheck.sh first"
  sleep 5
  cat << EOF
  Select your action:
  1) Install web server (Apache, nginx)
  2) Install DB server (MySQL/MariaDB, PGSQL)
  3) Install GitLab
  EOF

  read task

  case $task in
    1)
			clear
			cat << EOF
			Select webserver:
			a) Apache
			n) nginx
			EOF

			read webserver

			case $webserver in
				a)
        if [ "$OS" == "centos" -a "redhat" -a "fedora" ]; then
          { # Installs base Apache stack
          yum -y install httpd httpd-tools php php-common php-gd php-xmlrpc php-xml openssl openssl-devel
            # Starts Apache2 with Systemd or init script
            if [ "$SYS" == "systemd" ]; then
              systemctl start httpd && systemctl enable httpd
            elif [ "$SYS" == '/sbin/init' ]; then
              service httpd start && chkconfig httpd on
            fi } >> ~/hydration_log
          echo "Apache successfully installed with OpenSSL and PHP"
          echo "Check hydration_log for more details"
        elif [ "$OS" == "ubuntu" ]; then
          { # Installs base Apache stack
            apt-get -y install apache2 apache2-utils php5 php5-common php5-gd php5-xmlrpc php5-xml openssl openssl-devel
            # Starts Apache2 with Systemd or init script
            if [ "$SYS" == "systemd" ]; then
              systemctl start apache2 && systemctl enable apache2
            elif [ "$SYS" == '/sbin/init' ]; then
              service apache2 start && chkconfig apache2 on
            fi } >> ~/hydration_log
          echo "Apache successfully installed with OpenSSL and PHP"
          echo "Check hydration_log for more details"
				fi
				;;

      	n)
        if [ "$OS" == "centos" -a "redhat" ]; then
          { # Installs base nginx stack
          yum -y install nginx httpd-tools php php-common php-gd php-xmlrpc php-xml php-fpm openssl openssl-devel
            # Starts nginx and php-fpm with Systemd or init script
            if [ "$SYS" == "systemd" ]; then
              systemctl start nginx && systemctl enable nginx
              systemctl start php-fpm && systemctl enable php-fpm
            elif [ "$SYS" == '/sbin/init' ]; then
              service nginx start && chkconfig nginx on
              service php-fpm start && chkconfig nginx on
            fi } >> ~/hydration_log
          echo "nginx successfully installed with OpenSSL and PHP-FPM"
          echo "Check hydration_log for more details"
				elif [ "$OS" == "ubuntu" ]; then
					{ # Installs base nginx stack
					apt-get -y install nginx apache2-utils php5 php5-common php5-gd php5-xmlrpc php5-xml php5-fpm openssl openssl-devel
					# Starts nginx and php-fpm with Systemd or init script
					if [ "$SYS" == "systemd" ]; then
						systemctl start nginx && systemctl enable nginx
						systemctl start php5-fpm && systemctl enable php5-fpm
					elif [ "$SYS" == '/sbin/init' ]; then
						service nginx start && chkconfig nginx on
						service php5-fpm start && chkconfig nginx on
					fi } >> ~/hydration_log
					echo "nginx successfully installed with OpenSSL and PHP-FPM"
					echo "Check hydration_log for more details"
				fi
      	;;
				*)
					echo "Please enter a valid option"
					;;
				esac
    2)
      echo "MySQL/MariaDB or PGSQL? [m/p]"
      read dbserver
      if [ "$dbserver" == "m" ]; then
        if [ "$OS" == "centos" -a "redhat" ]; then
          { # Installs MySQL server
          yum -y install mysql mysql-server
            # Starts MariaDB/MySQL with Systemd or init script
            if [ "$SYS" == "systemd" ]; then
              systemctl start mysql && systemctl enable mysql
            elif [ "$SYS" == '/sbin/init' ]; then
              service mysql start && chkconfig mysql on
            fi
          fi } >> ~/hydration_log
          echo "MySQL successfully installed"
          echo "Check hydration_log for more details"

          elif [ "$OS" == "ubuntu" ]; then
            { # Installs MySQL server
            apt-get -y install mysql mysql-server
            # Starts MariaDB/MySQL with Ssytemd or init script
            if [ "$SYS" == "systemd" ]; then
              systemctl start mysql && systemctl enable mysql
            elif [ "$SYS" == '/sbin/init' ]; then
              service mysql start && chkconfig mysql on
            fi
          fi } >> ~/hydration_log
          echo "MySQL successfully installed"
          echo "Check hydration_log for more details"

      elif [ "$dbserver" == "p" ]; then
        if [ "$OS" == "centos" -a "redhat" ]; then
          { # Installs PostgreSQL/PGSQL
          yum -y install postgresql-server postgresql-contrib
          # Initializes base DB
          postgresql-setup init db
          # Changes Host-Based Auth file from identity to passwd auth
          sed -i -e 's/ident/md5/g' /var/lib/pgsql/data/pg_hba.conf
          # Starts PGSQL with Systemd or init script
          if [ "$SYS" == "systemd" ]; then
            systemctl start postgresql && systemctl enable postgresql
          elif [ "$SYS" == '/sbin/init' ]; then
            service postgresql start && chkconfig postgresql on
          fi
        fi } >> ~/hydration_log
        echo "PostgreSQL successfully installed"
        echo "Check hydration_log for more details"

        elif [ "$OS" == "ubuntu" ]; then
          { #Installes PostgreSQL/PGSQL
          apt-get update && apt-get -y install postgresql postgresql-contrib
          # Starts PGSQL with systemd or init script
          if [ "$SYS" == "systemd" ]; then
            systemctl start postgresql && systemctl enable postgresql
          elif [ "$SYS" == '/sbin/init' ]; then
            service postgresql start && chkconfig postgresql on
          fi
        fi } >> ~/hydration_log
        echo "PostgreSQL successfully installed"
        echo "Check hydration_log for more details"
        ;;
    *)
      echo "Please select a valid option"
      ;;
    esac
fi
