#!/usr/bin/env bash

function remove_fail2ban () {
    progress_message "Removing fail2ban"

    if is_service_running "fail2ban-server"; then
        progress_message "Stopping fail2ban"
    fi

     if dpkg-query -l | awk '/fail2ban/ { print $2 }' | grep -qwE "^fail2ban$"; then
        progress_message "Found fail2ban package installation. Removing"

        apt-get purge -qq -y fail2ban
        
     else
        info_message "Fail2ban package not found, possibly installed from source"

        rm -f /usr/local/bin/fail2ban-*

     fi

    [ -f /etc/systemd/system/multi-user.target.wants/fail2ban.service ] && \
        run unlink /etc/systemd/system/multi-user.target.wants/fail2ban.service
    [ -f /lib/systemd/system/fail2ban.service ] && run rm /lib/systemd/system/fail2ban.service

    progress_message "Removing fail2ban configuration"
    info_message "!! This action is not reversible !!"

    while [[ "${REMOVE_FAIL2BAN_CONFIG}" != "y" && "${REMOVE_FAIL2BAN_CONFIG}" != "n" ]]; do
        read -rp "Remove fail2ban configuration files? [y/n]: " -e REMOVE_FAIL2BAN_CONFIG
    done

    if [[ "${REMOVE_FAIL2BAN_CONFIG}" == y* || "${REMOVE_FAIL2BAN_CONFIG}" == Y* ]]; then
        [ -d /etc/fail2ban/ ] && rm -fr /etc/fail2ban/

        success_message "All configuration files deleted permanently."
    fi

    if is_installed "fail2ban-server"; then
        error_message "Unable to remove fail2ban server."
    fi

    success_message "Fail2ban server removed succesfully."

}

if is_not_installed "fail2ban-server"; then
    throw_info "Oops, fail2ban installation not found."
fi

while [[ "${REMOVE_FAIL2BAN}" != "y" && "${REMOVE_FAIL2BAN}" != "n" ]]; do
    read -rp "Are you sure to remove fail2ban? [y/n]: " -e REMOVE_FAIL2BAN
done

if [[ "$REMOVE_FAIL2BAN" != "Y" && "$REMOVE_FAIL2BAN" != "y" ]]; then
    throw_info "Found fail2ban server, but not removed."
fi

remove_fail2ban