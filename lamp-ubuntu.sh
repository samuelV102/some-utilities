#!/bin/bash

#######################################
# Bash script para instalar la pila LAMP en Ubuntu
# Author: Samuel (samuel@cygnus.com.uy)

declare -A opts_yes
opts_yes=([yes]=1 [YES]=1 [y]=1 [Y]=1)

# Verificar si se accedió como usuario root
if ((EUID)); then
  echo "Este script debe ejecutarse como root" 1>&2
  exit 1
fi

# Contraseña para el root de mysql
read -p 'db_root_password [secretpasswd]: ' db_root_password
echo

# Actualización del SO
apt update -y

## Instalación de apache
apt install apache2 -y
ufw allow in "Apache"
ufw status

# Instalación de MySQL database server
export DEBIAN_FRONTEND="noninteractive"
debconf-set-selections <<<"mysql-server mysql-server/root_password password $db_root_password"
debconf-set-selections <<<"mysql-server mysql-server/root_password_again password $db_root_password"
apt install mysql-server -y

## Instalación de PHP
apt install software-properties-common && add-apt-repository ppa:ondrej/php -y
apt update
sudo apt upgrade -y
apt install php8.1 libapache2-mod-php8.1 php8.1-mysql php8.1-fpm libapache2-mod-fcgid php-mbstring php-zip php-gd php-json php-curl-y
a2enmod proxy_fcgi setenvif && a2enconf php8.1-fpm
nano /etc/apache2/mods-enabled/dir.conf
systemctl reload apache2
systemctl status php8.1-fpm
php --version

# Habilitación de Mod Rewrite
a2enmod rewrite
php5enmod mcrypt

## Instalación de PhpMyAdmin
apt-get install wget zip unzip
wget -P ~/ https://files.phpmyadmin.net/phpMyAdmin/5.1.3/phpMyAdmin-5.1.3-all-languages.zip
wget -P ~/ https://files.phpmyadmin.net/phpmyadmin.keyring
gpg --import ~/phpmyadmin.keyring
wget -P ~/ https://files.phpmyadmin.net/phpMyAdmin/5.1.3/phpMyAdmin-5.1.3-all-languages.zip.asc
gpg --verify ~/phpMyAdmin-5.1.3-all-languages.zip.asc
mkdir /var/www/html/phpmyadmin
unzip ~/phpMyAdmin-5.1.3-all-languages.zip -d /var/www/html/phpmyadmin
cp /var/www/html/phpmyadmin/config.sample.inc.php /var/www/html/phpmyadmin/config.inc.php
nano /var/www/html/phpmyadmin/config.inc.php
chmod 660 /var/www/html/phpmyadmin/config.inc.php
chown -R www-data:www-data /var/www/html/phpmyadmin

# Configuracion general
chown -R www-data:www-data /var/www
systemctl reload apache2
