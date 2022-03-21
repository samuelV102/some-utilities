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

read -p 'Actualizar apt? [y/n]: ' r_apache2_opt
# Actualización del SO
if ((opts_yes[$r_apache2_opt])); then

  apt update -y
fi

read -p 'Instalar Apache2? [y/n]: ' r_apache2_opt
## Instalación de apache
if ((opts_yes[$r_apache2_opt])); then
  apt install apache2 -y
  ufw allow in "Apache"
  ufw status
fi

read -p 'Instalar Mysql? [y/n]: ' r_apache2_opt
# Instalación de MySQL database server
if ((opts_yes[$r_apache2_opt])); then
  # Contraseña para el root de mysql
  read -p 'db_root_password [secretpasswd]: ' db_root_password
  echo
  export DEBIAN_FRONTEND="noninteractive"
  debconf-set-selections <<<"mysql-server mysql-server/root_password password $db_root_password"
  debconf-set-selections <<<"mysql-server mysql-server/root_password_again password $db_root_password"
  apt install mysql-server -y
fi

read -p 'Instalar php 8.1? [y/n]: ' r_apache2_opt
## Instalación de PHP
if ((opts_yes[$r_apache2_opt])); then
  apt install software-properties-common && add-apt-repository ppa:ondrej/php -y
  apt update -y
  sudo apt upgrade -y
  apt install php8.1 libapache2-mod-php8.1 php8.1-mysql php8.1-fpm libapache2-mod-fcgid php-mbstring php-zip php-gd php-json php-curl php-xml php-intl php8.1-xdebug -y
  a2enmod proxy_fcgi setenvif && a2enconf php8.1-fpm
  nano /etc/apache2/mods-enabled/dir.conf
  systemctl reload apache2
  systemctl status php8.1-fpm
  php --version

  read -p 'Instalar archivo info.php? [y/n]: ' r_apache2_opt
  if ((opts_yes[$r_apache2_opt])); then
    cat config-files/info.php >>/var/www/html/info.php
  fi

  # Habilitación de Mod Rewrite
  a2enmod rewrite
  php5enmod mcrypt
fi

read -p 'Instalar phpmyadmin? [y/n]: ' r_apache2_opt
## Instalación de PhpMyAdmin
if ((opts_yes[$r_apache2_opt])); then
  apt install wget zip unzip -y
  wget -P ~/ https://files.phpmyadmin.net/phpMyAdmin/5.1.3/phpMyAdmin-5.1.3-all-languages.zip
  wget -P ~/ https://files.phpmyadmin.net/phpmyadmin.keyring
  gpg --import ~/phpmyadmin.keyring
  wget -P ~/ https://files.phpmyadmin.net/phpMyAdmin/5.1.3/phpMyAdmin-5.1.3-all-languages.zip.asc
  gpg --verify ~/phpMyAdmin-5.1.3-all-languages.zip.asc
  unzip ~/phpMyAdmin-5.1.3-all-languages.zip -d /var/www/html
  mv /var/www/html/phpMyAdmin-5.1.3-all-languages /var/www/html/phpmyadmin
  cp /var/www/html/phpmyadmin/config.sample.inc.php /var/www/html/phpmyadmin/config.inc.php
  nano /var/www/html/phpmyadmin/config.inc.php
  chmod 660 /var/www/html/phpmyadmin/config.inc.php
  chown -R www-data:www-data /var/www/html/phpmyadmin
fi

read -p 'Configurar permisos para los usuarios www-data y USER para el directorio /var/www? [y/n]: ' r_apache2_opt
if ((opts_yes[$r_apache2_opt])); then
  # Configuracion general
  usermod -a -G www-data $USER
  chown -R www-data:www-data /var/www
  chmod -R 775 /var/www
fi

read -p 'Reiniciar servidor apache2? [y/n]: ' r_apache2_opt
if ((opts_yes[$r_apache2_opt])); then
  systemctl reload apache2
fi

read -p 'Instalar y configurar herramientas de desarrollo? [y/n]: ' r_apache2_opt
if ((opts_yes[$r_apache2_opt])); then

  read -p 'Instalar y configurar node? [y/n]: ' r_apache2_opt
  if ((opts_yes[$r_apache2_opt])); then
    curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    apt install nodejs -y
    mkdir "${HOME}/.npm-packages"
    npm config set prefix "${HOME}/.npm-packages"
    cat config-files/.bashrc >>~/.bashrc
    source ~/.bashrc
    npm install -g npm@latest

    read -p 'Instalar y configurar yarn? [y/n]: ' r_apache2_opt
    if ((opts_yes[$r_apache2_opt])); then
      npm install --global yarn
      yarn --version
    fi
  fi

  read -p 'Instalar y configurar symfony? [y/n]: ' r_apache2_opt
  if ((opts_yes[$r_apache2_opt])); then
    echo 'deb [trusted=yes] https://repo.symfony.com/apt/ /' | tee /etc/apt/sources.list.d/symfony-cli.list
    apt update -y
    apt install symfony-cli
  fi

  read -p 'Instalar y configurar composer? [y/n]: ' r_apache2_opt
  if ((opts_yes[$r_apache2_opt])); then
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
  fi

  read -p 'Configurar puertos 8080 y 8081 para pruebas de aplicaciones symfony? [y/n]: ' r_apache2_opt
  if ((opts_yes[$r_apache2_opt])); then
    mkdir /var/www/symfony/public
    cat config-files/vhost-dev-symfony.conf >>/etc/apache2/sites-available/vhost-dev-symfony.conf
    cat config-files/vhost-prod-symfony.conf >>/etc/apache2/sites-available/vhost-prod-symfony.conf
  fi

fi
