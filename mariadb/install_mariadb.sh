#!/usr/bin/env bash

function secure_mariadb () {
    progress_message "Securing MariaDB Installation"

    # Ref: https://bertvv.github.io/notes-to-self/2015/11/16/automating-mysql_secure_installation/
    MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)}
    local SQL_QUERY=""

    # Setting the database root password.
    SQL_QUERY="ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"

    # Delete anonymous users.
    SQL_QUERY="${SQL_QUERY}
                DELETE FROM mysql.user WHERE User='';"
    
    # Ensure the root user can not log in remotely.
    SQL_QUERY="${SQL_QUERY}
                DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"

     # Remove the test database.
    SQL_QUERY="${SQL_QUERY}
            DROP DATABASE IF EXISTS test;
            DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"

     # Flush the privileges tables.
    SQL_QUERY="${SQL_QUERY}
            FLUSH PRIVILEGES;"

    # Root password is blank for newly installed MariaDB (MySQL).
    if mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -e "${SQL_QUERY}"; then
        success_message "Securing MariaDB server installation has been done."
        success_message "Root Password: ${MYSQL_ROOT_PASSWORD}"
    else
        throw_error "Unable to secure MariaDB server installation."
    fi

}

function add_mariadb_repo () {
    progress_message "Adding MariaDB repository"
    
    DISTRIB_NAME=${DISTRIB_NAME:-$(get_distrib_name)}
    RELEASE_NAME=${RELEASE_NAME:-$(get_release_name)}
    
    # Add MariaDB official repo.
    # Ref: https://mariadb.com/kb/en/library/mariadb-package-repository-setup-and-usage/
    MARIADB_REPO_SETUP_URL="https://downloads.mariadb.com/MariaDB/mariadb_repo_setup"

    if is_http_failed "${MARIADB_REPO_SETUP_URL}"; then
        throw_error "MariaDB repo installer not found."
    fi

    curl -sSL -o "${BUILD_DIR}/mariadb_repo_setup" "${MARIADB_REPO_SETUP_URL}" && \
    bash "${BUILD_DIR}/mariadb_repo_setup" --mariadb-server-version="mariadb-${MYSQL_VERSION}" \
        --os-type="${DISTRIB_NAME}" --os-version="${RELEASE_NAME}" && \
    apt-get update -qq -y
}


function install_mariadb () {

    add_mariadb_repo

    progress_message "Installing MariaDB (MySQL drop-in replacement) server"

    # Install MariaDB
    apt-get install -qq -y libmariadb3 libmariadbclient18 "mariadb-client-${MYSQL_VERSION}" \
        "mariadb-client-core-${MYSQL_VERSION}" mariadb-common mariadb-server "mariadb-server-${MYSQL_VERSION}" \
        "mariadb-server-core-${MYSQL_VERSION}" mariadb-backup

    secure_mariadb

    if is_not_installed "mysql"; then
        throw_error "Something went wrong with MariaDB server installation"
    fi            

    success_message "MariaDB server installed successfully"

}

# Start running things from a call at the end so if this script is executed
# after a partial download it doesn't do anything.
if is_installed "mysql"; then
    throw_info "MariaDB server already exists, installation skipped"
fi

FORCE_INSTALL_MARIADB=${1:-false}

if "${FORCE_INSTALL_MARIADB}"; then
    install_mariadb
else
    while [[ "${DO_INSTALL_MYSQL}" != y* && "${DO_INSTALL_MYSQL}" != n* ]]; do
        read -rp "Do you want to install MariaDB server? [y/n]: " -i y -e DO_INSTALL_MYSQL
    done

    if [[ "$DO_INSTALL_MYSQL" != "Y" && "$DO_INSTALL_MYSQL" != "y" ]]; then
        throw_info "MariaDB server installation skipped."
    fi

    install_mariadb
fi
