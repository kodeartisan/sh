#!/usr/bin/env bash

SELECTED_PHP=""
SELECTED_PHP_VER=""

function uninstall_php () {
    if is_not_installed "${SELECTED_PHP_VER}"; then
        throw_error "Oops, ${SELECTED_PHP_VER} packages installation not found."
    fi

    echo ""

    while [[ "${REMOVE_PHP}" != "Y" && "${REMOVE_PHP}" != "y" ]]; do
        read -rp "Are you sure to remove PHP package? [y/n]: " -e REMOVE_PHP
    done
    
    if [[ "$REMOVE_PHP" != "Y" && "$REMOVE_PHP" != "y" ]]; then
        throw_info "Found ${SELECTED_PHP_VER} packages, but not removed."
    fi

    progress_message "Uninstalling PHP packages"

    if is_service_running "php-fpm${SELECTED_PHP}"; then
        systemctl stop "${SELECTED_PHP_VER}-fpm"
    fi

    progress_message "Removing PECL extensions"

    pecl uninstall openswoole

     if dpkg-query -l | awk '/php/ { print $2 }' | grep -qwE "^${SELECTED_PHP_VER}"; then
        progress_message "Removing PHP ${SELECTED_PHP_VER} packages installation"

        # Remove PHP packages.
        # shellcheck disable=SC2046
        apt-get purge -qq -y $(dpkg-query -l | awk '/php/ { print $2 }' | grep -wE "^${SELECTED_PHP_VER}")

        # Remove PHP & FPM config files.

        echo ""

        while [[ "${REMOVE_PHP_CONFIG}" != "y" && "${REMOVE_PHP_CONFIG}" != "n" ]]; do
            read -rp "Remove PHP ${SELECTED_PHP} & FPM configuration files? [y/n]: " -e REMOVE_PHP_CONFIG
        done

        echo ""

        if [[ ${REMOVE_PHP_CONFIG} == Y* || ${REMOVE_PHP_CONFIG} == y* ]]; then
            [ -d "/etc/php/${PHPv}" ] && rm -fr "/etc/php/${PHPv}"
            success_message "All your configuration files deleted permanently."
        fi

        if is_installed "${SELECTED_PHP_VER}"; then
            error_message "Unable to remove PHP ${SELECTED_PHP} installation."
        else
            success_message "PHP ${SELE} package and it's extensions successfuly removed."
        fi
     else
        info_message "PHP ${SELECTED_PHP} package and it's extensions not found."
     fi
}


clear
echo ""
echo "Available PHP versions:"
echo "  1). PHP 7.4"
echo "  2). PHP 8.0"
echo "  3). PHP 8.1"
echo "  4). PHP 8.2"
echo "--------------------------------------------"
echo ""

while [[ "${SELECTED_PHP_TO_REMOVE}" != "1" && "${SELECTED_PHP_TO_REMOVE}" != "2" && "${SELECTED_PHP_TO_REMOVE}" != "3" && "${SELECTED_PHP_TO_REMOVE}" != "4" ]]; do
    read -rp "Select PHP Version: " -e SELECTED_PHP_TO_REMOVE
done

case "${SELECTED_PHP_TO_REMOVE}" in
    1)
        SELECTED_PHP="7.4"
        SELECTED_PHP_VER="php7.4"
    ;;
    2)
        SELECTED_PHP="8.0"
        SELECTED_PHP_VER="php8.0"
    ;;
    3)
        SELECTED_PHP="8.1"
        SELECTED_PHP_VER="php8.1"
    ;;
    4)
        SELECTED_PHP="8.2"
        SELECTED_PHP_VER="php8.2"
    ;;
    *)
        
    ;;
esac

uninstall_php "${SELECTED_PHP_TO_REMOVE}"

unset SELECTED_PHP_INSTALATION SELECTED_PHP SELECTED_PHP_VER

