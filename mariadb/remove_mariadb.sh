#!/usr/bin/env bash

function remove_config () {
    progress_message "Removing MariaDB (MySQL) configuration"
    info_message "!! This action is not reversible !!"

    while [[ "${REMOVE_MYSQL_CONFIG}" != "y" && "${REMOVE_MYSQL_CONFIG}" != "n" ]]; do
        read -rp "Remove MariaDB database and configuration files? [y/n]: " -e REMOVE_MYSQL_CONFIG
    done

    if [[ "${REMOVE_MYSQL_CONFIG}" == y* || "${REMOVE_MYSQL_CONFIG}" == Y* ]]; then
        [ -d /etc/mysql ] && rm -fr /etc/mysql
        [ -d /var/lib/mysql ] && rm -fr /var/lib/mysql

        success_message "All database and configuration files deleted permanently."
    fi
}


function remove_mariadb () {
    if is_service_running "mysqld"; then
        progress_message "Stopping mysql service"
        systemctl stop mysql
    fi

    if dpkg-query -l | awk '/mariadb/ { print $2 }' | grep -qwE "^mariadb-server-${MYSQL_VERSION}"; then
        progress_message "Found MariaDB ${MYSQL_VERSION} packages installation, removing"
        # Remove MariaDB server.
        apt-get purge -qq -y libmariadb3 libmariadbclient18 "mariadb-client-${MYSQL_VERSION}" \
            "mariadb-client-core-${MYSQL_VERSION}" mariadb-common mariadb-server "mariadb-server-${MYSQL_VERSION}" \
            "mariadb-server-core-${MYSQL_VERSION}" mariadb-backup
    elif dpkg-query -l | awk '/mysql/ { print $2 }' | grep -qwE "^mysql"; then
        progress_message "Found MySQL packages installation, removing"

        # Remove MySQL server.
        apt-get purge -qq -y mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-*
    fi

    remove_config
}

if is_not_installed "mysql"; then
    throw_error "Oops, MariaDB server installation not found"
fi

while [[ "${REMOVE_MARIADB}" != "y" && "${REMOVE_MARIADB}" != "n" ]]; do
    read -rp "Are you sure to remove MariaDB server? [y/n]: " -e REMOVE_MARIADB
done

if [[ "$REMOVE_MARIADB" != "Y" && "$REMOVE_MARIADB" != "y" ]]; then
    throw_info "Found MariaDB server, but not removed."
fi

remove_mariadb