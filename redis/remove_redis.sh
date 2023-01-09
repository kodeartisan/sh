#!/usr/bin/env bash

remove_redis () {
    # Stop Redis server process.
    if is_service_running "redis-server"; then
        systemctl stop redis-server
    fi   

    # Remove Redis server.
    if dpkg-query -l | awk '/redis/ { print $2 }' | grep -qwE "^redis-server"; then
        progress_message "Found Redis package installation. Removing"

        apt-get purge -qq -y $(dpkg-query -l | awk '/redis/ { print $2 }')
        add-apt-repository -y --remove ppa:redislabs/redis
    else
        info_message "Redis package not found, possibly installed from source."
        progress_message "Remove it manually!!"

        REDIS_BIN=$(command -v redis-server)

        progress_message "Deleting Redis binary executable: ${REDIS_BIN}"

        [[ -x "${REDIS_BIN}" ]] && rm -f "${REDIS_BIN}"
    fi

    # Remove Redis config files.
    info_message "!! This action is not reversible !!"

    while [[ "${REMOVE_REDIS_CONFIG}" != "y" && "${REMOVE_REDIS_CONFIG}" != "n" ]]; do
        read -rp "Remove Redis database and configuration files? [y/n]: " -e REMOVE_REDIS_CONFIG
    done

    if [[ "${REMOVE_REDIS_CONFIG}" == Y* || "${REMOVE_REDIS_CONFIG}" == y* ]]; then
        if [ -d /etc/redis ]; then
            run rm -fr /etc/redis
        fi
        if [ -d /var/lib/redis ]; then
            run rm -fr /var/lib/redis
        fi
        success_message "All your Redis database and configuration files deleted permanently."
    fi

    # Final test.
    systemctl daemon-reload

    if is_installed "redis-server"; then
        throw_error "Unable to remove Redis server."
    fi

    success_message "Redis server removed succesfully."
}

echo ""

if is_not_installed "redis-server"; then
    throw_info "Oops, Redis installation not found."
fi

while [[ "${REMOVE_REDIS}" != "y" && "${REMOVE_REDIS}" != "n" ]]; do
    read -rp "Are you sure to remove Redis server? [y/n]: " -i y -e REMOVE_REDIS
done

progress_message "Uninstalling Redis server"

if [[ "$REMOVE_REDIS" == "n" ]]; then
    throw_info "Found Redis server, but not removed."
fi

remove_redis


