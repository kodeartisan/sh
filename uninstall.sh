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

fi

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
        read -rp "Enter a Uninstaller from an option above: " -e SELECTED_DATABASE
    done

    clear

    case "${SELECTED_DATABASE}" in
        1)             
            if is_file_exists "./mariadb/remove_mariadb.sh"; then
                . ./mariadb/remove_mariadb.sh
            fi
        ;;
        2)
            if is_file_exists "./redis/remove_redis.sh"; then
                . ./redis/remove_redis.sh
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
        read -rp "Enter a Uninstaller from an option above: " -e SELECTED_PROGRAMMING
    done

    clear

    case "${SELECTED_PROGRAMMING}" in
        1)
            
            if is_file_exists "./php/remove_php.sh"; then
                . ./php/remove_php.sh
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

function select_webserver () {
    clear
    echo ""
    echo "  1). Nginx"
    echo "  2). Apache"
    echo "--------------------------------------------"
    echo ""

    while [[ "${SELECTED_WEBSERVER}" != "1" && "${SELECTED_WEBSERVER}" != "2" && "${SELECTED_WEBSERVER}" != "3" && "${SELECTED_WEBSERVER}" != "4" ]]; do
        read -rp "Enter a Uninstaller from an option above: " -e SELECTED_WEBSERVER
    done

    clear

    case "${SELECTED_WEBSERVER}" in
        1)
            if is_file_exists "./nginx/remove_nginx.sh"; then
                . ./nginx/remove_nginx.sh
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

function select_others() {
    clear
    echo ""
    echo "  1). Fail2ban"
    echo "--------------------------------------------"
    echo ""

    while [[ "${SELECTED_UNINSTALLER_OTHERS}" != "1" && "${SELECTED_UNINSTALLER_OTHERS}" != "2" && "${SELECTED_UNINSTALLER_OTHERS}" != "3" ]]; do
        read -rp "Enter a Uninstaller from an option above: " -e SELECTED_UNINSTALLER_OTHERS
    done

    clear

    case "${SELECTED_UNINSTALLER_OTHERS}" in
        1)
            
            if is_file_exists "./fail2ban/remove_fail2ban.sh"; then
                
                . ./fail2ban/remove_fail2ban.sh
            fi
        ;;
        2)
             
        ;;
        *)
            echo "default (none of above)"
        ;;
    esac
}


function select_uninstallers() {
    clear
    echo ""
    echo "Available Uninstaller:"
    echo "  1). Webserver"
    echo "  2). Programming"
    echo "  3). Database"
    echo "  4). DevOps"
    echo "  5). Others"
    echo "--------------------------------------------"
    echo ""

    while [[ "${SELECTED_UNINSTALLER}" != "1" && "${SELECTED_UNINSTALLER}" != "2" && "${SELECTED_UNINSTALLER}" != "3" && "${SELECTED_UNINSTALLER}" != "4" && "${SELECTED_UNINSTALLER}" != "5"  ]]; do
        read -rp "Enter a Uninstaller from an option above: " -e SELECTED_UNINSTALLER
    done

    case "${SELECTED_UNINSTALLER}" in
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
        #select_devops
     ;;
     5)
        select_others
     ;;
    esac
}

requires_root
select_uninstallers