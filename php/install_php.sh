#!/usr/bin/env bash

SELECTED_PHP=""
PHP_VERSION=""

function add_php_repo () {

    progress_message "Add Ondrej's PHP repository"
    
    DISTRIB_NAME=$(get_distrib_name)
    RELEASE_NAME=$(get_release_name)

    if [[ "${DISTRIB_NAME}" != "ubuntu" ]]; then
         throw_error "Unable to install PHP, this GNU/Linux distribution is not supported."   
    fi

    if is_file_exists "/etc/apt/sources.list.d/ondrej-${DISTRIB_NAME}-php-${RELEASE_NAME}.list"; then
        info_message "PHP package repository already exists."
    else
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 14AA40EC0831756756D7F66C4F4EA0AAE5267A6C
        add-apt-repository -y ppa:ondrej/php
    fi

    progress_message "Updating repository, please wait"
    apt-get update -qq -y
    
} 

function install_composer () {
    progress_message "Installing Composer"

    if is_installed "composer"; then
        throw_info "Composer already installed, instalation skipped"
    fi

    EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

    if [[ "${EXPECTED_SIGNATURE}" != "${ACTUAL_SIGNATURE}" ]]; then
        throw_error "Invalid PHP Composer installer signature"
    fi

    php composer-setup.php --install-dir=/usr/local/bin/ --filename=composer
    rm composer-setup.php

    if is_not_installed "composer"; then
        throw_error "omething went wrong with PHP Composer installation."
    fi

    success_message "PHP Composer successfully installed."
}

function install_php () {
    if is_installed "${SELECTED_PHP}"; then
        throw_info "PHP version already exists, installation skipped."
    fi

    add_php_repo

    progress_message "Preparing PHP ${SELECTED_PHP} installation..."

    local PHP_EXTS=("bcmath" "bz2" "cli" "common" "curl" "dev" "fpm" "gd" "gmp" "gnupg" \
            "imap" "intl" "mbstring" "mysql" "opcache" "pcov" "pgsql" "pspell" "readline" \
            "ldap" "snmp" "soap" "sqlite3" "tidy" "tokenizer" "xml" "xmlrpc" "xsl" "yaml" "zip" "mongodb" "redis" \
            "geoip" "gnupg" "imagick" "igbinary" "json" "mcrypt" "memcache" "memcached" "msgpack" "sodium")
    local PHP_REPO_EXTS=()   
    local PHP_PECL_EXTS=("openswoole")
       
    # Sort PHP extensions.
    #shellcheck disable=SC2207
    PHP_EXTS=($(printf "%s\n" "${PHP_EXTS[@]}" | sort -u | tr '\n' ' '))

    # Check additional PHP extensions availability.
    for EXT_NAME in "${PHP_EXTS[@]}"; do
        progress_message "Checking extension ${EXT_NAME}"

        # Search extension from repository or PECL.
        if apt-cache search "${SELECTED_PHP}-${EXT_NAME}" | grep -c "${SELECTED_PHP}-${EXT_NAME}" > /dev/null; then
            progress_message "[${SELECTED_PHP}-${EXT_NAME}]"
            PHP_REPO_EXTS+=("${SELECTED_PHP}-${EXT_NAME}")
        elif apt-cache search "php-${SELECTED_PHP}" | grep -c "php-${SELECTED_PHP}" > /dev/null; then
            progress_message "[${SELECTED_PHP}-${EXT_NAME}]"
            PHP_REPO_EXTS+=("php-${EXT_NAME}")           
        fi
        
    done

    # Install PHP and PHP extensions.
    progress_message "Installing PHP ${SELECTED_PHP} and it's extensions"


    if [[ "${#PHP_REPO_EXTS[@]}" -gt 0 ]]; then
        apt-get install -qq -y "${SELECTED_PHP}" "${PHP_REPO_EXTS[@]}" \
            dh-php php-common php-pear php-xml pkg-php-tools fcgiwrap spawn-fcgi
    fi

    if [[ "${#PHP_PECL_EXTS[@]}" -gt 0 ]]; then
        pecl install "${PHP_PECL_EXTS[@]}"
    fi

    if is_file_not_contains "/etc/php/${PHP_VERSION}/fpm/php.ini" "extension=swoole.so"; then
        progress_message "add the extension=swoole.so to the end of php.ini"
        append_to_file "/etc/php/${PHP_VERSION}/fpm/php.ini" "extension=swoole.so"
    fi

    # Reload PHP-FPM service.
    if is_service_running "php-fpm${PHP_VERSION}"; then
        progress_message "Restarting php-fpm${PHP_VERSION}"
        systemctl reload "php${PHP_VERSION}-fpm"
    fi

    # Install additional PHP extensions.
    if is_installed "${SELECTED_PHP}"; then
        success_message "PHP ${SELECTED_PHP} along with extensions installed."
    fi

    install_composer

    # Unset PHP extensions variables.
    unset PHP_EXTS PHP_REPO_EXTS PHP_PECL_EXTS

}

FORCE_INSTALL_PHP=${1:-false}

if "${FORCE_INSTALL_PHP}"; then
    PHP_VERSION=${2:-"8.2"}
    SELECTED_PHP="php${PHP_VERSION}"

    install_php "${SELECTED_PHP}"
    
else
    echo ""
    echo "Available PHP versions:"
    echo "  1). PHP 7.4"
    echo "  2). PHP 8.0"
    echo "  3). PHP 8.1"
    echo "  4). PHP 8.2"
    echo "--------------------------------------------"
    echo ""

    while [[ "${SELECTED_PHP_INSTALATION}" != "1" && "${SELECTED_PHP_INSTALATION}" != "2" && "${SELECTED_PHP_INSTALATION}" != "3" && "${SELECTED_PHP_INSTALATION}" != "4" ]]; do
        read -rp "Select PHP Version: " -e SELECTED_PHP_INSTALATION
    done

    case "${SELECTED_PHP_INSTALATION}" in
        1)
            SELECTED_PHP="php7.4"
            PHP_VERSION="7.4"
        ;;
        2)
            SELECTED_PHP="php8.0"
            PHP_VERSION="8.0"
        ;;
        3)
            SELECTED_PHP="php8.1"
            PHP_VERSION="8.1"
        ;;
        4)
            SELECTED_PHP="php8.2"
            PHP_VERSION="8.2"
        ;;
        *)
            
        ;;
    esac


    install_php "${SELECTED_PHP_INSTALATION}"
fi



unset SELECTED_PHP_INSTALATION SELECTED_PHP PHP_VERSION








