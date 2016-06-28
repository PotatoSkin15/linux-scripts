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
cat >/etc/.my.cnf << EOF
[client]
user=root
password="$sqlroot"
EOF
chmod 600 /etc/.my.cnf
echo 'MySQL root credentials stored in /etc/.my.cnf'

# Sets variables for dialog box
cmd=(dialog --separate-output --radiolist "Select software to install:" 22 76 16)
options=(1 "WordPress" off
         2 "Drupal 7" off
         3 "Drupal 8" off
         4 "Joomla!" off
         5 "Concrete5" off)

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

printf 'What is the sitename?'
read -r sname

printf 'What is your chosen username?'
read -r uname

printf 'What is your email?'
read -r email

printf 'Enter password for your account'
read -s passwd

choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear

for choice in $choices
do

case $choice in

1)
  echo 'Installing WordPress...'
  { # Get wp-cli first
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp

    # Creates base directory and downloads latest tarball
    mkdir -p /var/www/wordpress
    wget https://wordpress.org/latest.tar.gz && tar xzf latest.tar.gz -C /var/www/$sname

    # Creates MySQL DB and user
    mysql -u root password $sqlroot
    mysql -u root -p$sqlroot -e "create database wp_db";
    mysql -u root -p$sqlroot -e "grant all on wp_db* to 'wp_db_user'@'localhost' identified by '"$cmssql"'";

    cp /var/www/$sname/wp-config-sample.php /var/www/$sname/wp-config.php
    sed -i "s/'DB_NAME', 'database_name_here'/'DB_NAME', 'wp_db'/g" /var/www/$sname/wp-config.php
    sed -i "s/'DB_USER', 'username_here'/'DB_USER', 'wp_db_user'/g" /var/www/$sname/wp-config.php
    sed -i "s/'DB_PASSWORD', 'password_here'/'DB_PASSWORD', '$cmssql'/g" /var/www/$sname/wp-config.php

    for i in `seq 1 10`
    do
        wp_salt=$(</dev/urandom tr -dc 'a-zA-Z0-9!@#$%^&*()\-_ []{}<>~`+=,.;:/?|' | head -c 64 | sed -e 's/[\/&]/\\&/g');
        sed -i "0,/put your unique phrase here/s/put your unique phrase here/$wp_salt/" /var/www/$sname/wp-config.php
    done

    wp core install --allow-root --url=$sname --admin_user=$uname --admin_password=$passwd --admin_email=$email

    if [ "$srv" == 'apache2' || "$srv" == 'httpd' ]; then
      echo "<VirtualHost *:80>
      ServerName $sname

      DirectoryIndex index.html, index.php
      DocumentRoot /var/www/$sname

      <Directory />
        Options FollowSymLinks
        AllowOverride All
        Order deny,allow
        Deny from all
        Satisfy all
      </Directory>

      AccessFileName .htaccess
      <Directory /var/www/$sname/htdocs>
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

      </VirtualHost>" >> /etc/$srv/sites-available/$sname
      ln -s /etc/$srv/sites-available/$sname /etc/$srv/sites-enabled
      cd /var/www/$sname && chown -R :apache *
      chmod 444 /var/www/$sname/wp-config.php
      find -type d -exec chmod 755 {} + && find -type f -exec chmod 644 {} +
    elif [ "$srv" == 'nginx' ]; then
      mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
	  echo "server {
	        listen 80 $sname;
	        listen [::]:80 default_server ipv6only=on;
	        root /var/www/$sname;
	        index index.php index.html index.htm;
	        server_name localhost;
	        location / {
	             try_files $uri $uri/ /index.php?q=$uri&$args;
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
      }" >> /etc/$srv/sites-available/$sname
      ln -s /etc/$srv/sites-available/$sname /etc/$srv/sites-enabled
      cd /var/www/$sname && chown -R :www-data *
      chmod 444 /var/www/$sname/wp-config.php
      find -type d -exec chmod 755 {} + && find -type f -exec chmod 644 {} +
    elif [ "$srv" == 'lighttpd' ]; then
	  echo "$HTTP["host"] =~ "(^|www\.)"$sname"$" {
        server.document-root = "/var/www/$sname"
        accesslog.filename = "/var/log/lighttpd/$sname.access.log"
        server.error-handler-404 = "/index.php"
      }" >> /etc/lighttpd/lighttpd.conf
      touch /var/log/lighttpd/$sname.access.log
      cd /var/www/$sname && chown -R :www *
      chmod 444 /var/www/$sname/wp-config.php
      find -type d -exec chmod 755 {} + && find -type f -exec chmod 644 {} +
    fi

    if [ "$SYS" == 'systemd' ]; then
      systemctl restart $srv
    elif [ "$SYS" == 'init' ]; then
      service $srv restart
    fi} &> ~/deploycms_log
  echo 'Done. Check deploycms_log for more details'
;;

2)
  echo 'Installing Drupal 7...'
  { # Install Drush, the glorious Drupal CLI tool
    if [ "$OS" == 'ubuntu' ]; then
      apt-get update && apt-get -y install drush composer
    else
      cd /opt
      git clone https://github.com/drush-ops/drush.git
      mkdir composer
      cd composer
      curl -sS https://getcomposer.org/installer | php -d suhosin.executor.include.whitelist=phar
      cd ../drush
      php -d suhosin.executor.include.whitelist=phar /opt/composer/composer.phar install
      ln -s /opt/drush/drush /usr/bin/drush
      ln -s /opt/composer/composer.phar /usr/bin/composer
    fi

    # Gets latest Druapl 7 tarball and extracts it
    mkdir -p /var/www/$sname
    wget https://ftp.drupal.org/files/projects/drupal-7.44.tar.gz && tar xzf drupal-7.44.tar.gz -C /var/www/$sname

    # Changes group ownership for Drupal site files
    if [ "$srv" == 'apache2' || "$srv" == 'httpd' ]; then
      cd /var/www/$sname && chown -R :apache *
    elif [ "$srv" == 'nginx' ]; then
      cd /var/www/$sname && chown -R :www-data *
    elif [ "$srv" == 'lighttpd' ]; then
      cd /var/www/$sname && chown -R :www *
    fi

    # Copies default.settings.php to settings.php for Drupal to use and changes perms
    cp sites/default/default.settings.php sites/default/settings.php
    chmod 666 sites/default/settings.php && chmod g+w sites/default

    # Creates MySQL DB and user
    mysql -u root password $sqlroot
    mysql -u root -p$sqlroot -e "create database drupal_db";
    mysql -u root -p$sqlroot -e "grant all on drupal_db* to 'drupal_db_user'@'localhost' identified by '"$cmssql"'";

    drush site-install standard --db-url='mysql://drupal_db_user:'"$cmssql"'@localhost/drupal_db' --site-name=$sname --account-name=$uname --account-pass=$passwd
    drush dl views ctools ckeditor pathauto jquery_update date webform module_filter token adminimal_admin_menu adminimal_theme
    drush en -y views ctools ckeditor pathauto jquery_update date webform module_filter token adminimal_admin_menu adminimal_theme

    if [ "$srv" == 'apache2' || "$srv" == 'httpd' ]; then
	echo "<VirtualHost *:80>
      ServerName $sname

      DirectoryIndex index.html, index.php
      DocumentRoot /var/www/$sname

      <Directory />
        Options FollowSymLinks
        AllowOverride All
        Order deny,allow
        Deny from all
        Satisfy all
      </Directory>

      AccessFileName .htaccess
      <Directory /var/www/$sname/htdocs>
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

      </VirtualHost>" >> /etc/$srv/sites-available/$sname
      ln -s /etc/$srv/sites-available/$sname /etc/$srv/sites-enabled
      cd /var/www/$sname && find -type d -exec chmod 755 {} + && find -type f -exec chmod 644 {} +
      chown -R :apache *

    elif [ "$srv" == 'nginx' ]; then
      echo "server {
          server_name $sname;
          root /var/www/$sname;

          gzip_static on;

          location = /favicon.ico {
                  log_not_found off;
                  access_log off;
          }

          location = /robots.txt {
                  allow all;
                  log_not_found off;
                  access_log off;
          }

          location ~* \.(txt|log)$ {
                  allow 192.168.0.0/16;
                  deny all;
          }

          location ~ \..*/.*\.php$ {
                  return 403;
          }

          location ~ ^/sites/.*/private/ {
                  return 403;
          }

          location ~ (^|/)\. {
                  return 403;
          }

          location / {
                  try_files $uri @rewrite;
          }

          location @rewrite {
                  rewrite ^ /index.php;
          }

          location ~ \.php$ {
                  fastcgi_split_path_info ^(.+\.php)(/.+)$;
                  include fastcgi_params;
                  fastcgi_param SCRIPT_FILENAME $request_filename;
                  fastcgi_intercept_errors on;
                  fastcgi_pass unix:/var/run/php5-fpm.sock;
          }

          location ~ ^/sites/.*/files/styles/ {
                  try_files $uri @rewrite;
          }

          location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
                  expires max;
                  log_not_found off;
          }
      }" >> /etc/$srv/sites-available/$sname
      ln -s /etc/$srv/sites-available/$sname /etc/$srv/sites-enabled
      cd /var/www/$sname && find -type d -exec chmod 755 {} + && find -type f -exec chmod 644 {} +
      chown -R :www-data *

    elif [ "$srv" == 'lighttpd' ]; then
      echo "$SERVER["socket"] == ":80" {

        $HTTP["url"] =~ "^(/sites/(.)/files/backup_migrate/)" {
            url.access-deny = ("")
        }

        $HTTP["url"] =~ "/files/backup_migrate/" {
            url.access-deny = ( "" )
        }

        $HTTP["host"] =~ "(.).$sname$" {

        server.document-root = "/var/www/$sname"
        index-file.names = ( "index.php" )

        url.rewrite-once = ( "^/files/(.)$" => "/sites/%0/files/$1", "^/themes/(.)$" => "/sites/%0/themes/$1")

        url.rewrite-if-not-file = ("^\/([^\?])\?(.)$" => "/index.php?q=$1&$2", "^\/(.)$" => "/index.php?q=$1")

        $HTTP["url"] =~ "^(\/sites\/(.)\/files\/)" {
            $HTTP["url"] !~ "^(\/sites\/(.*)\/files\/imagecache\/)" {
                fastcgi.server = ()
                cgi.assign = ()
                scgi.server = ()
            }
        }

        url.access-deny = ( "~", ".engine", ".inc", ".info", ".install", ".module", ".profile", ".test", ".po", ".sh", ".sql", ".mysql", ".theme", ".tpl", ".xtmpl", "Entries", "Repository", "Root" )

        }
      }" >> /etc/$srv/sites-available/$sname
      ln -s /etc/$srv/sites-available/$sname /etc/$srv/sites-enabled
      cd /var/www/$sname && find -type d -exec chmod 755 {} + && find -type f -exec chmod 644 {} +
      chown -R :www *
    fi
    chmod -R g+w sites/default/files
    chmod 444 sites/default/settings.php

    if [ "$SYS" == 'systemd' ]; then
      systemctl restart $srv
    elif [ "$SYS" == 'init' ]; then
      service $srv restart
    fi} &> ~/deploycms_log
  echo 'Done. Check deploycms_log for more details'
;;

3)
  echo 'Installing Drupal 8...'
  { # Install Drush, the glorious Drupal CLI tool
    if [ "$OS" == 'ubuntu' ]; then
      apt-get update && apt-get -y install drush composer
    else
      cd /opt
      git clone https://github.com/drush-ops/drush.git
      mkdir composer
      cd composer
      curl -sS https://getcomposer.org/installer | php -d suhosin.executor.include.whitelist=phar
      cd ../drush
      php -d suhosin.executor.include.whitelist=phar /opt/composer/composer.phar install
      ln -s /opt/drush/drush /usr/bin/drush
      ln -s /opt/composer/composer.phar /usr/bin/composer
    fi

    # Creates MySQL DB and user
    mysql -u root password $sqlroot
    mysql -u root -p$sqlroot -e "create database drupal_db";
    mysql -u root -p$sqlroot -e "grant all on drupal_db* to 'drupal_db_user'@'localhost' identified by '"$cmssql"'";

    cd /var/www/
    composer create-project drupal-composer/drupal-project:~8.0 $sname --stability dev --no-interaction && cd drupal/web
    drush site-install --db-url='mysql://drupal_db_user:'"$cmssql"'@localhost/drupal_db' --site-name=$sname --account-name=$uname --account-pass=$passwd

    if [ "$srv" == 'apache2' || "$srv" == 'httpd' ]; then
      echo "<VirtualHost *:80>
      ServerName $sname

      DirectoryIndex index.html, index.php
      DocumentRoot /var/www/$sname

      <Directory />
        Options FollowSymLinks
        AllowOverride All
        Order deny,allow
        Deny from all
        Satisfy all
      </Directory>

      AccessFileName .htaccess
      <Directory /var/www/$sname>
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

      </VirtualHost>" >> /etc/$srv/sites-available/$sname
      ln -s /etc/$srv/sites-available/$sname /etc/$srv/sites-enabled
      cd /var/www/$sname && find -type d -exec chmod 755 {} + && find -type f -exec chmod 644 {} +
      chown -R :apache *

    elif [ "$srv" == 'nginx' ]; then
      echo "server {
          server_name $sname;
          root /var/www/$sname;

          gzip_static on;

          location = /favicon.ico {
                  log_not_found off;
                  access_log off;
          }

          location = /robots.txt {
                  allow all;
                  log_not_found off;
                  access_log off;
          }

          location ~* \.(txt|log)$ {
                  allow 192.168.0.0/16;
                  deny all;
          }

          location ~ \..*/.*\.php$ {
                  return 403;
          }

          location ~ ^/sites/.*/private/ {
                  return 403;
          }

          location ~ (^|/)\. {
                  return 403;
          }

          location / {
                  try_files $uri @rewrite;
          }

          location @rewrite {
                  rewrite ^ /index.php;
          }

          location ~ \.php$ {
                  fastcgi_split_path_info ^(.+\.php)(/.+)$;
                  include fastcgi_params;
                  fastcgi_param SCRIPT_FILENAME $request_filename;
                  fastcgi_intercept_errors on;
                  fastcgi_pass unix:/var/run/php5-fpm.sock;
          }

          location ~ ^/sites/.*/files/styles/ {
                  try_files $uri @rewrite;
          }

          location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
                  expires max;
                  log_not_found off;
          }
      }" >> /etc/$srv/sites-available/$sname
      ln -s /etc/$srv/sites-available/$sname /etc/$srv/sites-enabled
      cd /var/www/$sname && find -type d -exec chmod 755 {} + && find -type f -exec chmod 644 {} +
      chown -R :www-data *

    elif [ "$srv" == 'lighttpd' ]; then
      echo "$SERVER["socket"] == ":80" {

        $HTTP["url"] =~ "^(/sites/(.)/files/backup_migrate/)" {
            url.access-deny = ("")
        }

        $HTTP["url"] =~ "/files/backup_migrate/" {
            url.access-deny = ( "" )
        }

        $HTTP["host"] =~ "(.).$sname$" {

        server.document-root = "/var/www/$sname"
        index-file.names = ( "index.php" )

        url.rewrite-once = ( "^/files/(.)$" => "/sites/%0/files/$1", "^/themes/(.)$" => "/sites/%0/themes/$1")

        url.rewrite-if-not-file = ("^\/([^\?])\?(.)$" => "/index.php?q=$1&$2", "^\/(.)$" => "/index.php?q=$1")

        $HTTP["url"] =~ "^(\/sites\/(.)\/files\/)" {
            $HTTP["url"] !~ "^(\/sites\/(.*)\/files\/imagecache\/)" {
                fastcgi.server = ()
                cgi.assign = ()
                scgi.server = ()
            }
        }

        url.access-deny = ( "~", ".engine", ".inc", ".info", ".install", ".module", ".profile", ".test", ".po", ".sh", ".sql", ".mysql", ".theme", ".tpl", ".xtmpl", "Entries", "Repository", "Root" )

        }
      }" >> /etc/$srv/sites-available/$sname
      ln -s /etc/$srv/sites-available/$sname /etc/$srv/sites-enabled
      cd /var/www/$sname && find -type d -exec chmod 755 {} + && find -type f -exec chmod 644 {} +
      chown -R :www *
    fi
    chmod -R g+w sites/default/files
    chmod 444 $sname/sites/default/settings.php && chmod 444 $sname/sites/default/services.yml

    if [ "$SYS" == 'systemd' ]; then
      systemctl restart $srv
    elif [ "$SYS" == 'init' ]; then
      service $srv restart
    fi} &> ~/deploycms_log
  echo 'Done. Check deploycms_log for more details'
;;

4)
  echo 'Installing Joomla!'
  { # Installs Composer to install joomlatools console
  if [ "$OS" == 'ubuntu' ]; then
    apt-get update && apt-get install composer
    composer global require joomlatools/console && export PATH="$PATH:~/.composer/vendor/bin" >> ~/.bashrc
    source ~/.bashrc
  else
    cd /opt
    mkdir composer
    cd composer
    curl -sS https://getcomposer.org/installer | php -d suhosin.executor.include.whitelist=phar
    php -d suhosin.executor.include.whitelist=phar /opt/composer/composer.phar install
    ln -s /opt/composer/composer.phar /usr/bin/composer
    composer global require joomlatools/console && export PATH="$PATH:~/.composer/vendor/bin" >> ~/.bashrc
    source ~/.bashrc
  fi

  # Creates MySQL DB and user
  mysql -u root password $sqlroot
  mysql -u root -p$sqlroot -e "create database joomla_db";
  mysql -u root -p$sqlroot -e "grant all on joomla_db* to 'joomla_db_user'@'localhost' identified by '"$cmssql"'";

  mkdir -p /var/www/$sname && cd /var/www/$sname
  joomla site:create $sname --www=/var/www/$sname --mysql-database=joomla_db --mysql-login=joomla_db_user:$cmssql

    if [ "$srv" == 'apache2' || "$srv" == 'httpd' ]; then
      echo "<VirtualHost *:80>
      ServerName $sname

      DirectoryIndex index.html, index.php
      DocumentRoot /var/www/$sname

      <Directory />
        Options FollowSymLinks
        AllowOverride All
        Order deny,allow
        Deny from all
        Satisfy all
      </Directory>

      AccessFileName .htaccess
      <Directory /var/www/$sname>
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

      </VirtualHost>" >> /etc/$srv/sites-available/$sname
      ln -s /etc/$srv/sites-available/$sname /etc/$srv/sites-enabled
      cd /var/www/$sname && find -type d -exec chmod 755 {} + && find -type f -exec chmod 644 {} +
      chown -R :apache *

    elif [ "$srv" == 'nginx' ]; then
      echo "server {
        listen 80;
        server_name $sname;
        server_name_in_redirect off;
        root /var/www/$sname;
        index index.php index.html index.htm default.html default.htm;

        location / {
            try_files $uri $uri/ /index.php?$args;
        }

        # deny running scripts inside writable directories
        location ~* /(images|cache|media|logs|tmp)/.*\.(php|pl|py|jsp|asp|sh|cgi)$ {
            return 403;
            error_page 403 /403_error.html;
         }

        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_intercept_errors on;
            fastcgi_pass unix:/var/run/php5-fpm.sock;
            fastcgi_index index.php;
        }

        location ~* \.(ico|pdf|flv)$ {
            expires 1y;
        }

        location ~* \.(js|css|png|jpg|jpeg|gif|swf|xml|txt)$ {
            expires 14d;
        }
      }" >> /etc/$srv/sites-available/$sname
      ln -s /etc/$srv/sites-available/$sname /etc/$srv/sites-enabled
      cd /var/www/$sname && find -type d -exec chmod 755 {} + && find -type f -exec chmod 644 {} +
      chown -R :www-data *

    elif [ "$srv" == 'lighttpd' ]; then
      echo "$HTTP["host"] =~ "(^|www\.)"$sname"$" {
          server.document-root = "/var/www/$sname"
          accesslog.filename = "/var/log/lighttpd/$sname.access.log"
          server.error-handler-404 = "/index.php"
        }" >> /etc/lighttpd/lighttpd.conf
        cd /var/www/$sname && find -type d -exec chmod 755 {} + && find -type f -exec chmod 644 {} +
        chown -R :web *
    fi

    if [ "$SYS" == 'systemd' ]; then
      systemctl restart $srv
    elif [ "$SYS" == 'init' ]; then
      service $srv restart
    fi} &> ~/deploycms_log
  echo 'Done. Joomla default credentials are admin/admin.'
  echo 'Check deploycms_log for more details'
;;

esac

done

fi
