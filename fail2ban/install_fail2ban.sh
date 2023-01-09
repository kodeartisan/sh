#!/usr/bin/env bash

function configure_fail2ban () {
    progress_message "Configuring Fail2ban"

    SSH_PORT=${SSH_PORT:-22}

    # Enable jail
    cat > /etc/fail2ban/jail.local <<EOL
[DEFAULT]
# banned for 30 days
bantime = 30d
# ignored ip (googlebot) - https://ipinfo.io/AS15169
ignoreip = 66.249.64.0/19 66.249.64.0/20 66.249.80.0/22 66.249.84.0/23 66.249.88.0/24
[sshd]
enabled = true
port = ssh,${SSH_PORT}
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
[nginx-http-auth]
enabled = true
port = http,https,8082,8083
maxretry = 3
EOL
    
}

function install_fail2ban () {
    progress_message "Installing Fail2ban from repository"

    apt-get install -qq -y fail2ban

    configure_fail2ban

    progress_message "Starting Fail2ban server"
    systemctl start fail2ban

    if is_not_installed "fail2ban-server"; then
        throw_error "Something went wrong with Fail2ban installation."
    fi

    success_message "Fail2ban server started successfully."
}

if is_installed "fail2ban-server"; then
    throw_info "Fail2ban already exists, installation skipped"
fi

while [[ "${DO_INSTALL_FAIL2BAN}" != "y" && "${DO_INSTALL_FAIL2BAN}" != "Y" && \
    "${DO_INSTALL_FAIL2BAN}" != "n" && "${DO_INSTALL_FAIL2BAN}" != "N" ]]; do
    read -rp "Do you want to install fail2ban server? [y/n]: " -e DO_INSTALL_FAIL2BAN
done

if [[ "$DO_INSTALL_FAIL2BAN" != "Y" && "$DO_INSTALL_FAIL2BAN" != "y" ]]; then
    throw_info "Fail2ban installation skipped."
fi

install_fail2ban