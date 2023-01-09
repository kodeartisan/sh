#!/usr/bin/env bash

function remove_nginx_configuration () {
    info_message "!! This action is not reversible !!"

    rm -fr /etc/nginx
    rm -fr /var/cache/nginx
    rm -fr /usr/share/nginx

    success_message "All your Nginx configuration files deleted permanently"
}


function remove_nginx () {
    if is_service_running "nginx"; then
        systemctl stop nginx
    fi

    if [[ ${NGX_VERSION} == "mainline" || ${NGX_VERSION} == "latest" ]]; then
        local NGINX_REPO="nginx-mainline"
    else
        local NGINX_REPO="nginx"
    fi

    # Remove nginx installation.
    if dpkg-query -l | awk '/nginx/ { print $2 }' | grep -qwE "^nginx-stable"; then
        progress_message "Found nginx-stable package installation, removing"

        apt-get purge -qq -y $(dpkg-query -l | awk '/nginx/ { print $2 }' | grep -wE "^nginx")
        add-apt-repository -y --remove ppa:nginx/stable

    elif dpkg-query -l | awk '/nginx/ { print $2 }' | grep -qwE "^nginx-custom"; then
        progress_message "Found nginx-custom package installation, removing"

        apt-get purge -qq -y $(dpkg-query -l | awk '/nginx/ { print $2 }' | grep -wE "^nginx")
        add-apt-repository -y --remove ppa:rtcamp/nginx

    elif dpkg-query -l | awk '/nginx/ { print $2 }' | grep -qwE "^nginx"; then
        progress_message "Found nginx package installation, removing"

        apt-get purge -qq -y $(dpkg-query -l | awk '/nginx/ { print $2 }' | grep -wE "^nginx") $(dpkg-query -l | awk '/libnginx/ { print $2 }' | grep -wE "^libnginx")
        add-apt-repository -y --remove "ppa:ondrej/${NGINX_REPO}"

    else
        progress_message "Nginx package not found, possibly installed from source."
    fi

     # Remove nginx config files.
     
     remove_nginx_configuration

    # Final test.

    systemctl daemon-reload
    if is_installed "nginx"; then
        throw_error "Unable to remove Nginx HTTP server"
    fi

    success_message "Nginx HTTP server removed succesfully"
}

while [[ "${REMOVE_NGINX}" != "y" && "${REMOVE_NGINX}" != "n" ]]; do
    read -rp "Are you sure to remove Nginx HTTP server? [y/n]: " -i y -e REMOVE_NGINX
done

if [[ "$REMOVE_NGINX" != "Y" && "$REMOVE_NGINX" != "y" ]]; then
    throw_info "Found Nginx HTTP server, but not removed."
fi

if is_not_installed "nginx"; then
    throw_info "Oops, Nginx installation not found"
fi

remove_nginx