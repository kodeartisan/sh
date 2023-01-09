#!/usr/bin/env bash

function install_certbot () {
    progress_message "Installing Certbot Let's Encrypt client"

    add-apt-repository -y ppa:certbot/certbot
    apt-get update -qq -y
    apt-get install -qq -y certbot python3-certbot-nginx

    if [[ -d /etc/letsencrypt/accounts/acme-v02.api.letsencrypt.org/directory ]]; then
        certbot update_account --email "${ADMIN_EMAIL}" --no-eff-email --agree-tos
    else
        certbot register --email "${ADMIN_EMAIL}" --no-eff-email --agree-tos
    fi

    systemctl status snap.certbot.renew.service

}


if is_installed "certbot"; then
    throw_info "Certbot Let's Encrypt already exists, installation skipped"
fi

while [[ "${DO_INSTALL_CERTBOT}" != "y" && "${DO_INSTALL_CERTBOT}" != "n" ]]; do
    read -rp "Do you want to install Certbot Let's Encrypt client? [y/n]: " -i y -e DO_INSTALL_CERTBOT
done

if [[ "$DO_INSTALL_CERTBOT" != "Y" && "$DO_DO_INSTALL_CERTBOTINSTALL_MYSQL" != "y" ]]; then
    throw_info "Certbot installation skipped."
fi

install_certbot