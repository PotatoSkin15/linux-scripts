#!/bin/bash

clear

# Check distribution before installing packages
OS=`grep -Eiom 1 'CentOS|RedHat|ol|Ubuntu|debian|Fedora|suse|amzn' /proc/version | head -1 | tr '[:upper:]' '[:lower:]'`

# Check for Systemd vs sysvinit
SYS=`ps -p 1 | grep -Eiom 1 'systemd|init'`

# Check for web server software and DB engine
srv=`ls /etc | grep -Eiom 1 'Apache2|httpd|nginx|lighttpd' | tr '[:upper:]' '[:lower:]'`
db=`ls /var/lib | grep -Eiom 1 'mysql' | head -1`
sqlroot=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev`
cmssql=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev`

# Creates my.cnf file
cat >/root/.my.cnf << EOF
[client]
user=root
password="$sqlroot"
EOF
chmod 600 /root/.my.cnf

# Sets variables for dialog box
cmd=(dialog --separate-output --checklist "Select software to install:" 22 76 16)
options=(1 "WordPress" off
         2 "Drupal 7" off
         3 "Drupal 8" off
         3 "Joomla!" off
         4 "Concrete5" off)

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

    # Creates MySQL DB and user
    mysql -u root password $sqlroot
    mysql -u root -p$sqlroot -e "create database wp_db";
    mysql -u root -p$sqlroot -e "grant all on wp_db* to wp_db_user@localhost identified by '"$cmssql"'";

    cp /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php
    sed -i "s/'DB_NAME', 'database_name_here'/'DB_NAME', 'wp_db'/g" /tmp/wordpress/wp-config.php;
    sed -i "s/'DB_USER', 'username_here'/'DB_USER', 'wp_db_user'/g" /tmp/wordpress/wp-config.php;
    sed -i "s/'DB_PASSWORD', 'password_here'/'DB_PASSWORD', '$cmssql'/g" /tmp/wordpress/wp-config.php;

    for i in `seq 1 10`
    do
        wp_salt=$(</dev/urandom tr -dc 'a-zA-Z0-9!@#$%^&*()\-_ []{}<>~`+=,.;:/?|' | head -c 64 | sed -e 's/[\/&]/\\&/g');
        sed -i "0,/put your unique phrase here/s/put your unique phrase here/$wp_salt/" /tmp/wordpress/wp-config.php;
    done

    if [ "$srv" == 'apache2' || "$srv" == 'httpd' ]; then
      cat > /etc/$srv/sites-available/default << EOF
      <VirtualHost *:80>
      # Admin email, Server Name (domain name) and any aliases
      ServerName localhost

      # Index file and Document Root (where the public files are located)
      DirectoryIndex index.html, index.php
      DocumentRoot /var/www/wordpress/htdocs

      # Custom log file locations
      <Directory />
        Options FollowSymLinks
        AllowOverride All
        Order deny,allow
        Deny from all
        Satisfy all
      </Directory>

      AccessFileName .htaccess
      <Directory /var/www/wordpress/htdocs>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
      </Directory>


      ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
      <Directory "/var/www/cgi-bin">
        AllowOverride None
        Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
        Order allow,deny
        Allow from all
      </Directory>

      </VirtualHost>
      EOF
      cd /var/www/wordpress && chown -R :apache *
      chmod 444 /var/www/wordpress/wp-config.php
      find -type d -exec chmod 755 {} + && find -type f -exec chmod 644 {} +
    elif [ "$srv" == 'nginx' ]; then
      mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
      cat > /etc/nginx/sites-available/default << "EOF"
      server {
	        listen 80 default_server;
	        listen [::]:80 default_server ipv6only=on;
	        root /var/www/wordpress;
	        index index.php index.html index.htm;
	        server_name localhost;
	        location / {
			         # First attempt to serve request as file, then
		           # as directory, then fall back to displaying a 404.
	             try_files $uri $uri/ /index.php?q=$uri&$args;
			         # Uncomment to enable naxsi on this location
			         # include /etc/nginx/naxsi.rules
	        }

          error_page 404 /404.html;
	        error_page 500 502 503 504 /50x.html;
	        location = /50x.html {
			    root /usr/share/nginx/html;
	        }

	        location ~ \.php$ {
			    try_files $uri =404;
			    fastcgi_split_path_info ^(.+\.php)(/.+)$;
			    fastcgi_pass unix:/var/run/php5-fpm.sock;
			    fastcgi_index index.php;
			    include fastcgi.conf;
	        }
      }
      EOF
      cd /var/www/wordpress && chown -R :www-data *
      chmod 444 /var/www/wordpress/wp-config.php
      find -type d -exec chmod 755 {} + && find -type f -exec chmod 644 {} +
    elif [ "$srv" == 'lighttpd' ]; then
      cat >> /etc/lighttpd/lighttpd.conf << "EOF"
      $HTTP["host"] =~ "(^|www\.)example.com$" {
        server.document-root = "/var/www/wordpress"
        accesslog.filename = "/var/log/lighttpd/example.com-access.log"
        server.error-handler-404 = "/index.php"
      }
      EOF
      touch /var/log/lighttpd/wordpress.access.log
      cd /var/www/wordpress && chown -R :www *
      chmod 444 /var/www/wordpress/wp-config.php
      find -type d -exec chmod 755 {} + && find -type f -exec chmod 644 {} +
    fi

    if [ "$SYS" == 'systemd' ]; then
      systemctl restart $srv
    elif [ "$SYS" == 'init' ]; then
      service $srv restart
    fi} &> ~/deploycms_log
  echo 'Done. Check deploycms_log for more details'
;;

esac

done

fi
