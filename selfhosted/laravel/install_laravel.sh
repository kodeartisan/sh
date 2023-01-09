#!/usr/bin/env bash

function configure_ufw () {
    progress_message "Configuring UFW"

    ufw enable
    
    # Close all incoming ports.
    ufw default deny incoming

    # Open all outgoing ports.
    ufw default allow outgoing

    # Open SSH port.
    ufw allow "${SSH_PORT}/tcp"

    # Open HTTP port.
    ufw allow 80

    # Open HTTPS port.
    ufw allow 443

    # Open DNS port.
    ufw allow 53
    
}

function install_laravel () {
    if is_not_installed "nginx"; then
        throw_error "Please install Nginx"
    fi

    if is_not_installed "php"; then
        throw_error "Please install php"
    fi

    if is_not_installed "mysql"; then
        throw_error "Please install Mysql"
    fi

    if is_not_installed "redis-server"; then
        throw_error "Please install redis"
    fi

    configure_ufw
   
}


echo ""
while [[ "${DO_INSTALL_LARAVEL}" != "y" && "${DO_INSTALL_LARAVEL}" != "n" ]]; do
    read -rp "Do you want to install Laravel? [y/n]: " -i y -e DO_INSTALL_LARAVEL
done

if [[ "$DO_INSTALL_LARAVEL" != "Y" && "$DO_INSTALL_LARAVEL" != "y" ]]; then
    throw_info "Laravel server installation skipped."
fi

install_laravel