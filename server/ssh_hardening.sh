#!/usr/bin/env bash

function create_user () {
    USERNAME=${ADMIN_USERNAME:-$(generate_random_username 8)}
    PASSWORD=${ADMIN_PASSWORD:-$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)}
    
    if is_username_not_available "${ADMIN_USERNAME}"; then
        throw_error "Unable to create account, username ${ADMIN_USERNAME} already exists."
    fi

    useradd -d "/home/${USERNAME}" -m -s /bin/bash "${USERNAME}"
    echo "${USERNAME}:${PASSWORD}" | chpasswd
    usermod -aG coder "${USERNAME}"

     # Create default directories.
    mkdir -p "/home/${USERNAME}/webapps" && \
    mkdir -p "/home/${USERNAME}/logs" && \
    mkdir -p "/home/${USERNAME}/.ssh" && \
    chmod 700 "/home/${USERNAME}/.ssh" && \
    touch "/home/${USERNAME}/.ssh/authorized_keys" && \
    chmod 600 "/home/${USERNAME}/.ssh/authorized_keys" && \
    chown -hR "${USERNAME}:${USERNAME}" "/home/${USERNAME}"

    # Add account credentials to /srv/.htpasswd.
    [ ! -f "/srv/.htpasswd" ] && touch /srv/.htpasswd

    # Protect .htpasswd file.
    chmod 0600 /srv/.htpasswd
    chown www-data:www-data /srv/.htpasswd
    
    # Generate password hash.
    if [[ -n $(command -v mkpasswd) ]]; then
        PASSWORD_HASH=$(mkpasswd --method=sha-256 "${PASSWORD}")
        sed -i "/^${USERNAME}:/d" /srv/.htpasswd
        echo "${USERNAME}:${PASSWORD_HASH}" >> /srv/.htpasswd
    elif [[ -n $(command -v htpasswd) ]]; then
        htpasswd -b /srv/.htpasswd "${USERNAME}" "${PASSWORD}"
    else
        PASSWORD_HASH=$(openssl passwd -1 "${PASSWORD}")
        sed -i "/^${USERNAME}:/d" /srv/.htpasswd
        echo "${USERNAME}:${PASSWORD_HASH}" >> /srv/.htpasswd
    fi

    success_message "User successfully created"
    success_message "Username: ${USERNAME}"
    success_message "Password: ${PASSWORD}"

}

function securing_ssh () {
    USERNAME=${ADMIN_USERNAME}
    if [[ "${SSH_PASSWORDLESS}" == true ]]; then
        echo "
Before starting, let's create a pair of keys that some hosts ask for during installation of the server.
On your local machine, open new terminal and create an SSH key pair using the ssh-keygen tool,
use the following command:
ssh-keygen -t rsa -b ${SSH_KEY_HASH_LENGTH}
After this step, you will have the following files: id_rsa and id_rsa.pub (private and public keys).
Never share your private key.
"
        sleep 3

        progress_message "Open your public key (id_rsa.pub) file, copy paste the key here"

        RSA_PUB_KEY=${RSA_PUB_KEY:-""}
        while ! [[ ${RSA_PUB_KEY} =~ ssh* ]]; do
            read -rp ": " -e RSA_PUB_KEY
        done

        # Grand access to SSH with key.
        if [[ ${RSA_PUB_KEY} =~ ssh* ]]; then
             progress_message "Securing your SSH server with public key"

             if is_folder_not_exists "/home/${USERNAME}/.ssh"; then
                mkdir -p "/home/${USERNAME}/.ssh" && \
                chmod 700 "/home/${USERNAME}/.ssh"
             fi

             if is_file_not_exists "/home/${USERNAME}/.ssh/authorized_keys"; then
                touch "/home/${USERNAME}/.ssh/authorized_keys" && \
                chmod 600 "/home/${USERNAME}/.ssh/authorized_keys"
             fi

             # Create authorized_keys file and copy your public key here.
             cat >> "/home/${USERNAME}/.ssh/authorized_keys" <<EOL
${RSA_PUB_KEY}
EOL
            success_message "RSA public key added to the authorized_keys"

            # Fix authorized_keys file ownership and permission.
            chown -hR "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.ssh"
            chmod 700 "/home/${USERNAME}/.ssh"
            chmod 600 "/home/${USERNAME}/.ssh/authorized_keys"

            progress_message "Enable SSH password-less login"

            bash -c "echo -e '\n\n#LEMPer custom config' >> /etc/ssh/sshd_config"

            # Restrict root login directly, use sudo user instead.
            SSH_ROOT_LOGIN=${SSH_ROOT_LOGIN:-false}
            if [[ "${SSH_ROOT_LOGIN}" == false ]]; then
                progress_message "Restricting SSH root login"

                if grep -qwE "^PermitRootLogin\ [a-z]*" /etc/ssh/sshd_config; then
                    sed -i "s/^PermitRootLogin\ [a-z]*/PermitRootLogin\ no/g" /etc/ssh/sshd_config
                else
                    #run sed -i "/^#PermitRootLogin/a PermitRootLogin\ no" /etc/ssh/sshd_config
                    bash -c "echo 'PermitRootLogin no' >> /etc/ssh/sshd_config"
                fi
            fi

            # Enable RSA key authentication.
            if grep -qwE "^RSAAuthentication\ no" /etc/ssh/sshd_config; then
                sed -i "s/^RSAAuthentication\ no/RSAAuthentication\ yes/g" /etc/ssh/sshd_config
            else
                #run sed -i "/^#RSAAuthentication/a RSAAuthentication\ yes" /etc/ssh/sshd_config
                bash -c "echo 'RSAAuthentication yes' >> /etc/ssh/sshd_config"
            fi

            # Enable pub key authentication.
            if grep -qwE "^PubkeyAuthentication\ no" /etc/ssh/sshd_config; then
                sed -i "s/^PubkeyAuthentication\ no/PubkeyAuthentication\ yes/g" /etc/ssh/sshd_config
            else
                #run sed -i "/^#PubkeyAuthentication/a PubkeyAuthentication\ yes" /etc/ssh/sshd_config
                bash -c "echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config"
            fi
            
            # Disable password authentication for password-less login using key.
            if grep -qwE "^PasswordAuthentication\ [a-z]*" /etc/ssh/sshd_config; then
                sed -i "s/^PasswordAuthentication\ [a-z]*/PasswordAuthentication\ no/g" /etc/ssh/sshd_config
            else
                #run sed -i "/^#PasswordAuthentication/a PasswordAuthentication\ no" /etc/ssh/sshd_config
                bash -c "echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config"
            fi

            if grep -qwE "^ClientAliveInterval\ [0-9]*" /etc/ssh/sshd_config; then
                sed -i "s/^ClientAliveInterval\ [0-9]*/ClientAliveInterval\ 600/g" /etc/ssh/sshd_config
            else
                #run sed -i "/^#ClientAliveInterval/a ClientAliveInterval\ 600" /etc/ssh/sshd_config
                bash -c "echo 'ClientAliveInterval 600' >> /etc/ssh/sshd_config"
            fi

            if grep -qwE "^ClientAliveCountMax\ [0-9]*" /etc/ssh/sshd_config; then
                sed -i "s/^ClientAliveCountMax\ [0-9]*/ClientAliveCountMax\ 3/g" /etc/ssh/sshd_config
            else
                #run sed -i "/^#ClientAliveCountMax/a ClientAliveCountMax\ 3" /etc/ssh/sshd_config
                bash -c "echo 'ClientAliveCountMax 3' >> /etc/ssh/sshd_config"
            fi

        fi
    fi
}

while [[ "${DO_SECURE_SERVER}" != "y" && "${DO_SECURE_SERVER}" != "n" ]]; do
    read -rp "Do you want to enable basic server security? [y/n]: " -i y -e DO_SECURE_SERVER
done

if [[ "$DO_SECURE_SERVER" != "Y" && "$DO_SECURE_SERVER" != "y" ]]; then
    throw_info "SSH Hardening skipped."
fi

create_user
securing_ssh
#install_firewall
