#!/usr/bin/env bash

function add_nginx_repo () {
    progress_message "Add Nginx repository"

    # Nginx version.
    local NGINX_VERSION=${NGINX_VERSION:-"stable"}
    export NGX_PACKAGE

    if [[ ${NGINX_VERSION} == "mainline" || ${NGINX_VERSION} == "latest" ]]; then
        local NGINX_REPO="nginx-mainline"
    else
        local NGINX_REPO="nginx"
    fi

    wget -qO "/etc/apt/trusted.gpg.d/${NGINX_REPO}.gpg" "https://packages.sury.org/${NGINX_REPO}/apt.gpg"
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 14AA40EC0831756756D7F66C4F4EA0AAE5267A6C
    add-apt-repository -y "ppa:ondrej/${NGINX_REPO}"
    apt-get update -qq -y

}

function configure_nginx_extra_modules () {
    progress_message "Creating Nginx configuration"

    # Enable Dynamic modules.
}


function add_nginx_modules () {
    local EXTRA_MODULE_PKGS=()

    progress_message "Installing Nginx with extra modules"

    # Auth PAM
    if "${NGX_HTTP_AUTH_PAM}"; then
        progress_message "Adding ngx-http-auth-pam module"
        EXTRA_MODULE_PKGS+=("libnginx-mod-http-auth-pam")
    fi

    # Brotli compression
    if "${NGX_HTTP_BROTLI}"; then
        progress_message "Adding ngx-http-brotli module"
        EXTRA_MODULE_PKGS+=("libnginx-mod-brotli")
    fi

        # Cache Purge
    if "${NGX_HTTP_CACHE_PURGE}"; then
        progress_message "Adding ngx-http-cache-purge module..."
        EXTRA_MODULE_PKGS+=("libnginx-mod-http-cache-purge")
    fi

        # Fancy indexes module for the Nginx web server
    if "${NGX_HTTP_DAV_EXT}"; then
        progress_message "Adding ngx-http-dav-ext module..."
        EXTRA_MODULE_PKGS+=("libnginx-mod-http-dav-ext")
    fi

    # Echo Nginx
    if "${NGX_HTTP_ECHO}"; then
        progress_message "Adding ngx-http-echo module..."
        EXTRA_MODULE_PKGS+=("libnginx-mod-http-echo")
    fi

    # Fancy indexes module for the Nginx web server
    if "${NGX_HTTP_FANCYINDEX}"; then
        progress_message "Adding ngx-http-fancyindex module..."
        EXTRA_MODULE_PKGS+=("libnginx-mod-http-fancyindex")
    fi

    # HTTP Geoip module.
    if "${NGX_HTTP_GEOIP}"; then
        progress_message "Adding ngx-http-geoip module"
        EXTRA_MODULE_PKGS+=("libmaxminddb" "libnginx-mod-http-geoip" "libnginx-mod-stream-geoip")
    fi

        # GeoIP2
    if "${NGX_HTTP_GEOIP2}"; then
        progress_message "Adding ngx-http-geoip2 module"
        EXTRA_MODULE_PKGS=("${EXTRA_MODULE_PKGS[@]}" "libmaxminddb" "libnginx-mod-http-geoip2" "libnginx-mod-stream-geoip2")
    fi

        # Headers more module.
    if "${NGX_HTTP_HEADERS_MORE}"; then
        progress_message "Adding ngx-http-headers-more-filter module"
        EXTRA_MODULE_PKGS+=("libnginx-mod-http-headers-more-filter")
    fi

    # HTTP Image Filter module.
    if "${NGX_HTTP_IMAGE_FILTER}"; then
        progress_message "Adding ngx-http-image-filter module"
        EXTRA_MODULE_PKGS=("${EXTRA_MODULE_PKGS[@]}" "libnginx-mod-http-image-filter")
    fi

    # Embed the power of Lua into Nginx HTTP Servers.
    if "${NGX_HTTP_LUA}"; then
        progress_message "Adding ngx-http-lua module"
        EXTRA_MODULE_PKGS=("${EXTRA_MODULE_PKGS[@]}" "luajit" "libluajit" "libnginx-mod-http-lua")
    fi

    # Nginx Memc - An extended version of the standard memcached module.
    if "${NGX_HTTP_MEMCACHED}"; then
        progress_message "Adding ngx-http-memcached module"
        #EXTRA_MODULE_PKGS=("${EXTRA_MODULE_PKGS[@]}" "libnginx-mod-http-memcached")
    fi

    # NGX_HTTP_NAXSI is an open-source, high performance, low rules maintenance WAF for NGINX.
    if "${NGX_HTTP_NAXSI}"; then
        progress_message "Adding ngx-http-naxsi (Web Application Firewall) module"
        #EXTRA_MODULE_PKGS=("${EXTRA_MODULE_PKGS[@]}" "libnginx-mod-naxsi")
    fi

    # NDK adds additional generic tools that module developers can use in their own modules.
    if "${NGX_HTTP_NDK}"; then
        progress_message "Adding ngx-http-ndk Nginx Devel Kit module"
        EXTRA_MODULE_PKGS+=("libnginx-mod-http-ndk")
    fi

    # NJS is a subset of the JavaScript language that allows extending nginx functionality.
    # shellcheck disable=SC2153
    if "${NGX_HTTP_JS}"; then
        progress_message "Adding ngx-http-js module"
        #EXTRA_MODULE_PKGS=("${EXTRA_MODULE_PKGS[@]}" "libnginx-mod-js")
    fi
    
    # Nginx upstream module for the Redis 2.0 protocol.
    if "${NGX_HTTP_REDIS2}"; then
        progress_message "Adding ngx-http-redis module"
        #EXTRA_MODULE_PKGS=("${EXTRA_MODULE_PKGS[@]}" "libnginx-mod-http-redis2")
    fi

    # A filter module which can do both regular expression and fixed string substitutions for nginx
    if "${NGX_HTTP_SUBS_FILTER}"; then
        progress_message "Adding ngx-http-subs-filter module"
        EXTRA_MODULE_PKGS+=("libnginx-mod-http-subs-filter")
    fi

    # Upstream Fair
    if "${NGX_HTTP_UPSTREAM_FAIR}"; then
        progress_message "Adding ngx-http-nginx-upstream-fair module"
        EXTRA_MODULE_PKGS+=("libnginx-mod-http-upstream-fair")
    fi

    # Nginx virtual host traffic status module
    if "${NGX_HTTP_VTS}"; then
        progress_message "Adding ngx-http-module-vts (VHost traffic status) module"
        #EXTRA_MODULE_PKGS=("${EXTRA_MODULE_PKGS[@]}" "libnginx-mod-http-vts")
    fi

    # HTTP XSLT module.
    if "${NGX_HTTP_XSLT_FILTER}"; then
        progress_message "Adding ngx-http-xslt-filter module"
        EXTRA_MODULE_PKGS+=("libnginx-mod-http-xslt-filter")
    fi

    # Mail module.
    if "${NGX_MAIL}"; then
        progress_message "Adding ngx-mail module"
        EXTRA_MODULE_PKGS+=("libnginx-mod-mail")
    fi

    # Nchan, pub/sub queuing server
    if "${NGX_NCHAN}"; then
        progress_message "Adding ngx-nchan (Pub/Sub) module"
        EXTRA_MODULE_PKGS+=("libnginx-mod-nchan")
    fi

    # NGINX-based Media Streaming Server.
    if "${NGX_RTMP}"; then
        progress_message "Adding ngx-rtmp (Media Streaming Server) module"
        EXTRA_MODULE_PKGS+=("libnginx-mod-rtmp")
    fi

    # Stream module.
    if "${NGX_STREAM}"; then
        progress_message "Adding ngx-stream module"
        EXTRA_MODULE_PKGS+=("libnginx-mod-stream")
    fi

    echo "${EXTRA_MODULE_PKGS[@]}"
}


function install_nginx () {
    #add_nginx_repo

    progress_message "Installing Nginx from package repository"

    local EXTRA_MODULES=$(add_nginx_modules)
    echo "${EXTRA_MODULE_PKGS[@]}"
    # Install Nginx and its modules.
    apt-get install -y nginx-extras "${EXTRA_MODULE_PKGS[@]}"
    
    progress_message "Configuring Nginx extra modules"


}

if is_installed "nginx"; then
    throw_info "Nginx web server already exists, installation skipped."
fi

FORCE_INSTALL_NGINX=${1:-false}

if "${FORCE_INSTALL_NGINX}"; then
    install_nginx
else
    while [[ ${DO_INSTALL_NGINX} != "y" && ${DO_INSTALL_NGINX} != "n" ]]; do
        read -rp "Do you want to install Nginx HTTP server? [y/n]: " -i y -e DO_INSTALL_NGINX
    done

    if [[ "$DO_INSTALL_NGINX" != "Y" && "$DO_INSTALL_NGINX" != "y" ]]; then
        throw_info "Nginx server installation skipped."
    fi

    install_nginx

fi



