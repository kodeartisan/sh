#!/usr/bin/env bash

# Work even if somebody does "bash lemper.sh".
set -e

# Try to re-export global path.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Get installer base directory.
export BASEDIR && \
BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )

# Include helper functions.
if [ "$(type -t run)" != "function" ]; then
    . ./utils/message.sh
    . ./utils/is.sh
    . ./utils/helper.sh
    . ./utils/generator.sh
    . ./utils/array.sh
    . ./utils/string.sh

    include_env ".env"
    include_env "./redis/.env"
    include_env "./nginx/.env"
    include_env "./mariadb/.env"
    include_env "./selfhosted/laravel/.env"
fi

function required_dependencies() {
    if is_not_installed "unzip"; then
        . ./server/install_dependencies.sh
        . ./server/cleanup_server.sh
        enable_swap
    fi
}

function select_devops () {
    clear
    echo ""
    echo "  1). Docker"
    echo "  2). Ansible"
    echo "  2). Terraform"
    echo "--------------------------------------------"
    echo ""
}

function select_webserver () {
    clear
    echo ""
    echo "  1). Nginx"
    echo "  2). Apache"
    echo "--------------------------------------------"
    echo ""

    while [[ "${SELECTED_WEBSERVER}" != "1" && "${SELECTED_WEBSERVER}" != "2" && "${SELECTED_WEBSERVER}" != "3" && "${SELECTED_WEBSERVER}" != "4" ]]; do
        read -rp "Enter a Instalation from an option above: " -e SELECTED_WEBSERVER
    done

    clear

    case "${SELECTED_WEBSERVER}" in
        1)
            if is_file_exists "./nginx/install_nginx.sh"; then
                . ./nginx/install_nginx.sh
            fi
           
        ;;
        2)
            
        ;;
        *)
            echo "default (none of above)"
        ;;
    esac

    unset SELECTED_WEBSERVER
}

function select_database () {
    clear
    echo ""
    echo "  1). Mariadb"
    echo "  2). Redis"
    echo "  3). PostgreSQL"
    echo "  4). MongoDB"
    echo "--------------------------------------------"
    echo ""

    while [[ "${SELECTED_DATABASE}" != "1" && "${SELECTED_DATABASE}" != "2" && "${SELECTED_DATABASE}" != "3" && "${SELECTED_DATABASE}" != "4" ]]; do
        read -rp "Enter a Instalation from an option above: " -e SELECTED_DATABASE
    done

    clear

    case "${SELECTED_DATABASE}" in
        1)
            if is_file_exists "./mariadb/install_mariadb.sh"; then
                . ./mariadb/install_mariadb.sh
            fi
           
        ;;
        2)
            if is_file_exists "./redis/install_redis.sh"; then
                . ./redis/install_redis.sh
            fi
        ;;
        *)
            echo "default (none of above)"
        ;;
    esac
}

function select_programming () {
    clear
    echo ""
    echo "  1). PHP"
    echo "  2). Nodejs"
    echo "  3). MongoDB"
    echo "--------------------------------------------"
    echo ""

    while [[ "${SELECTED_PROGRAMMING}" != "1" && "${SELECTED_PROGRAMMING}" != "2" && "${SELECTED_PROGRAMMING}" != "3" ]]; do
        read -rp "Enter a Instalation from an option above: " -e SELECTED_PROGRAMMING
    done

    clear

    case "${SELECTED_PROGRAMMING}" in
        1)
            
            if is_file_exists "./php/install_php.sh"; then
                
                . ./php/install_php.sh
            fi
        ;;
        2)
            echo "item = 2 or item = 3"
        ;;
        *)
            echo "default (none of above)"
        ;;
    esac
   
}

function select_self_hosted() {
    clear
    echo ""
    echo "  1). Laravel"
    echo "--------------------------------------------"
    echo ""

    while [[ "${SELECTED_HOSTED}" != "1" ]]; do
        read -rp "Enter a Instalation from an option above: " -e SELECTED_HOSTED
    done

    clear

    case "${SELECTED_HOSTED}" in
        1)
            
            if is_file_exists "./selfhosted/laravel/install_laravel.sh"; then
                
                . ./selfhosted/laravel/install_laravel.sh
            fi
        ;;
        2)
            
        ;;
        *)
            echo "default (none of above)"
        ;;
    esac
}

function select_others() {
    clear
    echo ""
    echo "  1). SSH Hardening"
    echo "  2). Fail2ban"
    echo "  3). Certbot"
    echo "--------------------------------------------"
    echo ""

    while [[ "${SELECTED_OTHERS}" != "1" && "${SELECTED_OTHERS}" != "2" && "${SELECTED_OTHERS}" != "3" ]]; do
        read -rp "Enter a Instalation from an option above: " -e SELECTED_OTHERS
    done

    clear

    case "${SELECTED_OTHERS}" in
        1)
            
            if is_file_exists "./server/ssh_hardening.sh"; then
                
                . ./server/ssh_hardening.sh
            fi
        ;;
        2)
            if is_file_exists "./fail2ban/install_fail2ban.sh"; then
                
                . ./fail2ban/install_fail2ban.sh
            fi
        ;;
        3)
             if is_file_exists "./certbot/install_certbot.sh"; then
                
                . ./certbot/install_certbot.sh
            fi
        ;;
        *)
            echo "default (none of above)"
        ;;
    esac
}

function select_instalations() {
    echo ""
    echo "Available Instalation:"
    echo "  1). Webserver"
    echo "  2). Programming"
    echo "  3). Database"
    echo "  4). DevOps"
    echo "  5). Self-hosted"
    echo "  6). Others"
    echo "--------------------------------------------"
    echo ""
    while [[ "${SELECTED_INSTALATION}" != "1" && "${SELECTED_INSTALATION}" != "2" && "${SELECTED_INSTALATION}" != "3" && "${SELECTED_INSTALATION}" != "4" && "${SELECTED_INSTALATION}" != "5" && "${SELECTED_INSTALATION}" != "6" ]]; do
        read -rp "Enter a Instalation from an option above: " -e SELECTED_INSTALATION
    done

    case "${SELECTED_INSTALATION}" in
     1)
        select_webserver    
     ;;
     2)
        select_programming
     ;;
     3)
        select_database
     ;;
     4)
        select_devops
     ;;
     5)
        select_self_hosted
     ;;
      6)
        select_others
     ;;
    esac
   
   
}

requires_root
preflight_system_check
required_dependencies
select_instalations






