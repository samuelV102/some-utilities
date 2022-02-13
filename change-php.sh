#!/bin/bash

declare -A opts_yes
opts_yes=([yes]=1 [YES]=1 [y]=1 [Y]=1)

if ((!EUID)); then
    if [ ! -z "${1}" ]; then
        echo "Se deshabilita: php${1}"
        if [ ! -z "${2}" ]; then
            echo "Se habilita: php${2}"
            update-alternatives --set php /usr/bin/php$2
            update-alternatives --set phar /usr/bin/phar$2
            update-alternatives --set phar.phar /usr/bin/phar.phar$2
            a2dismod php$1
            a2enmod php$2

            read -p "Reiniciar Apache2 [y/n]: " r_apache2_opt

            if ((opts_yes[$r_apache2_opt])); then
                systemctl restart apache2
                echo "Apache2 reiniciado"
            fi
        else
            echo "Es necesario que especifique la version de php que quiere habilitar"
        fi
    else
        echo "Es necesario que especifique la version de php que quiere deshabilitar"
    fi
else
    echo "No tiene suficientes permisos para continuar"
fi
