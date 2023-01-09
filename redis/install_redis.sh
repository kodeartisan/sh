#!/usr/bin/env bash

function configure_redis () {
    [[ ! -f /etc/redis/redis.conf ]] && cp -f etc/redis/redis.conf /etc/redis/

    # Custom Redis configuration.local RAM_SIZE && \
    local RAM_SIZE && \
        RAM_SIZE=$(get_ram_size)
    
    if [[ ${RAM_SIZE} -le 1024 ]]; then
        # If machine RAM less than / equal 1GiB, set Redis max mem to 1/8 of RAM size.
        local REDISMEM_SIZE=$((RAM_SIZE / 8))
    elif [[ ${RAM_SIZE} -gt 1024 && ${RAM_SIZE} -le 8192 ]]; then
        # If machine RAM less than / equal 8GiB and greater than 2GiB, 
        # set Redis max mem to 1/4 of RAM size.
        local REDISMEM_SIZE=$((RAM_SIZE / 4))
    else
        # Otherwise, set to max of 2048MiB.
        local REDISMEM_SIZE=2048
    fi

    # Optimize Redis config.
    cat >> /etc/redis/redis.conf <<EOL
 ####################################
# Custom configuration for LEMPer
#
maxmemory ${REDISMEM_SIZE}mb
maxmemory-policy allkeys-lru
EOL
    # Is Redis password protected enable?
    if [[ "${REDIS_REQUIRE_PASSWORD}" == true ]]; then
        progress_message "Configure Redis requirepass password"

        REDIS_PASSWORD=${REDIS_PASSWORD:-$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)}

        # Update Redis config.
                cat >> /etc/redis/redis.conf <<EOL
requirepass ${REDIS_PASSWORD}
EOL
    fi
    
    # Custom kernel optimization for Redis.
    progress_message "Configure Redis kernel optimization."

    cat >> /etc/sysctl.conf <<EOL
# Redis key-value store.
net.core.somaxconn=65535
vm.overcommit_memory=1
EOL

    sysctl -w net.core.somaxconn=65535 && \
    sysctl -w vm.overcommit_memory=1 && \
    bash -c "echo never > /sys/kernel/mm/transparent_hugepage/enabled"

    if [[ ! -f /etc/rc.local ]]; then
        touch /etc/rc.local
    fi

    # Make the change persistent.
    cat >> /etc/rc.local <<EOL
###################################################################
# Custom optimization for LEMPer
#
echo never > /sys/kernel/mm/transparent_hugepage/enabled
EOL

    # Init Redis script.
    if [[ ! -f /etc/init.d/redis-server ]]; then
        cp -f etc/init.d/redis-server /etc/init.d/
        chmod ugo+x /etc/init.d/redis-server
    fi

    # Setup Systemd service.
    if [[ ! -f /lib/systemd/system/redis-server.service ]]; then
        cp -f etc/systemd/redis-server.service /lib/systemd/system/

        if [[ ! -f /etc/systemd/system/redis.service ]]; then
            ln -s /lib/systemd/system/redis-server.service /etc/systemd/system/redis.service
        fi

        # Reloading systemctl daemon.
        systemctl daemon-reload
    fi

    # Restart and enable Redis on system boot.
    progress_message "Starting Redis server"

    if [[ -f /etc/systemd/system/redis.service || -f /lib/systemd/system/redis-server.service ]]; then
        systemctl enable redis-server.service
    fi

    systemctl restart redis-server.service

    if is_service_running "redis-server"; then
        success_message "Redis server started successfully."
    else
        throw_error "Something went wrong with Redis installation"
    fi
}

function install_redis () {
    echo ""
    while [[ "${DO_INSTALL_REDIS}" != "y" && "${DO_INSTALL_REDIS}" != "n" ]]; do
        read -rp "Do you want to install Redis server? [y/n]: " -i y -e DO_INSTALL_REDIS
    done

    if [[ "$DO_INSTALL_REDIS" != "Y" && "$DO_INSTALL_REDIS" != "y" ]]; then
        throw_info "Redis server installation skipped."
    fi

    progress_message "Adding Redis repository"

    add-apt-repository -y ppa:redislabs/redis && apt-get update -q -y

    progress_message "Installing Redis server from repository"

    apt-get install -q -y redis redis-tools

    configure_redis

}

if is_installed "redis-server"; then
    throw_info "Redis server already exists, installation skipped."
fi

install_redis