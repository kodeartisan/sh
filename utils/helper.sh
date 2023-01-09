#!/usr/bin/env bash

function include_env() {
    if [ -f "$1" ]; then
        # Clean environemnt first.
        # shellcheck source=.env.dist
        # shellcheck disable=SC2046
        unset $(grep -v '^#' "$1" | grep -v '^\[' | sed -E 's/(.*)=.*/\1/' | xargs)

        # shellcheck source=.env.dist
        # shellcheck disable=SC1094
        source <(grep -v '^#' "$1" | grep -v '^\[' | sed -E 's|^(.+)=(.*)$|: ${\1=\2}; export \1|g')
    fi
}

function requires_root() {
    if [ "$(id -u)" -ne 0 ]; then
        throw_error "This command can only be used by root."
    fi
}

function get_release_name() {
    if [[ -f "/etc/os-release" ]]; then
        # Export os-release vars.
        . /etc/os-release

        # Export lsb-release vars.
        [ -f /etc/lsb-release ] && . /etc/lsb-release

        # Get distribution name.
        [[ "${ID_LIKE}" == "ubuntu" ]] && DISTRIB_NAME="ubuntu" || DISTRIB_NAME=${ID:-"unsupported"}

        # Get distribution release / version ID.
        DISTRO_VERSION=${VERSION_ID:-"${DISTRIB_RELEASE}"}
        MAJOR_RELEASE_VERSION=$(echo ${DISTRO_VERSION} | awk -F. '{print $1}')

        case ${DISTRIB_NAME} in
            debian)
                RELEASE_NAME=${VERSION_CODENAME:-"unsupported"}

                # TODO for Debian install
                case ${MAJOR_RELEASE_VERSION} in
                    9)
                        RELEASE_NAME="stretch"
                    ;;
                    10)
                        RELEASE_NAME="buster"
                    ;;
                    11)
                        RELEASE_NAME="bullseye"
                    ;;
                    *)
                        RELEASE_NAME="unsupported"
                    ;;
                esac
            ;;
            ubuntu)
                # Hack for Linux Mint release number.
                [[ "${DISTRIB_ID}" == "LinuxMint" || "${ID}" == "linuxmint" ]] && \
                    DISTRIB_RELEASE="LM${MAJOR_RELEASE_VERSION}"

                case "${DISTRIB_RELEASE}" in
                    "18.04"|"LM19")
                        # Ubuntu release 18.04, LinuxMint 19
                        RELEASE_NAME=${UBUNTU_CODENAME:-"bionic"}
                    ;;
                    "20.04"|"LM20")
                        # Ubuntu release 20.04, LinuxMint 20
                        RELEASE_NAME=${UBUNTU_CODENAME:-"focal"}
                    ;;
                    "22.04"|"LM21")
                        # Ubuntu release 22.04, LinuxMint 21
                        RELEASE_NAME=${UBUNTU_CODENAME:-"jammy"}
                    ;;
                    *)
                        RELEASE_NAME="unsupported"
                    ;;
                esac
            ;;
            amzn)
                # Amazon based on RHEL/CentOS
                RELEASE_NAME="unsupported"

                # TODO for Amzn install
            ;;
            centos)
                # CentOS
                RELEASE_NAME="unsupported"

                # TODO for CentOS install
            ;;
            *)
                RELEASE_NAME="unsupported"
            ;;
        esac
    elif [[ -e /etc/system-release ]]; then
    	RELEASE_NAME="unsupported"
    else
        # Red Hat /etc/redhat-release
    	RELEASE_NAME="unsupported"
    fi

    echo "${RELEASE_NAME}"
}

# Get general distribution name.
function get_distrib_name() {
    if [[ -f "/etc/os-release" ]]; then
        # Export os-release vars.
        . /etc/os-release

        # Export lsb-release vars.
        [ -f /etc/lsb-release ] && . /etc/lsb-release

        # Get distribution name.
        [[ "${ID_LIKE}" == "ubuntu" ]] && DISTRIB_NAME="ubuntu" || DISTRIB_NAME=${ID:-"unsupported"}
    elif [[ -e /etc/system-release ]]; then
    	DISTRIB_NAME="unsupported"
    else
        # Red Hat /etc/redhat-release
    	DISTRIB_NAME="unsupported"
    fi

    echo "${DISTRIB_NAME}"
}

# Enable swap.
function enable_swap() {
    progress_message "Checking swap"

    if free | awk '/^Swap:/ {exit !$2}'; then
        local SWAP_SIZE && \
        SWAP_SIZE=$(free -m | awk '/^Swap:/ { print $2 }')
        progress_message "Swap size ${SWAP_SIZE}MiB."
    else
        progress_message "No swap detected."
        create_swap
        success_message "Swap created and enabled."
    fi
}

function preflight_system_check () {

    export DISTRIB_NAME && DISTRIB_NAME=$(get_distrib_name)
    export RELEASE_NAME && RELEASE_NAME=$(get_release_name)

    # Check supported distribution and release version.
    if [[ "${DISTRIB_NAME}" == "unsupported" || "${RELEASE_NAME}" == "unsupported" ]]; then
        throw_error "This Linux distribution isn't supported yet."
    fi

    # Set default timezone.
    export TIMEZONE
    if [[ -z "${TIMEZONE}" || "${TIMEZONE}" == "none" ]]; then
        [ -f /etc/timezone ] && TIMEZONE=$(cat /etc/timezone) || TIMEZONE="UTC"
    fi

     # Set ethernet interface.
    export IFACE && \
    IFACE=$(find /sys/class/net -type l | grep -e "eno\|ens\|enp\|eth0" | cut -d'/' -f5)

    if [ ! -d "${BUILD_DIR}" ]; then
        mkdir -p "${BUILD_DIR}"
    fi
}


# Get physical RAM size.
function get_ram_size() {
    local RAM_SIZE

    # Calculate RAM size in MB.
    RAM_SIZE=$(dmidecode -t 17 | awk '( /Size/ && $2 ~ /^[0-9]+$/ ) { x+=$2 } END{ print x}')

    echo "${RAM_SIZE}"
}

function create_swap () {
    local SWAP_FILE="/swapfile"
    local RAM_SIZE && \
    RAM_SIZE=$(get_ram_size)

    if [[ ${RAM_SIZE} -le 2048 ]]; then
        # If machine RAM less than / equal 2GiB, set swap to 2x of RAM size.
        local SWAP_SIZE=$((RAM_SIZE * 2))
    elif [[ ${RAM_SIZE} -gt 2048 && ${RAM_SIZE} -le 32768 ]]; then
        # If machine RAM less than / equal 8GiB and greater than 2GiB, set swap equal to RAM size + 1x.
        local SWAP_SIZE=$((4096 + (RAM_SIZE - 2048)))
    else
        # Otherwise, set swap to max of the physical / allocated memory.
        local SWAP_SIZE="${RAM_SIZE}"
    fi

    progress_message "Creating ${SWAP_SIZE}MiB swap..."

    # Create swap.
    fallocate -l "${SWAP_SIZE}M" ${SWAP_FILE} && \
    chmod 600 ${SWAP_FILE} && \
    chown root:root ${SWAP_FILE} && \
    mkswap ${SWAP_FILE} && \
    swapon ${SWAP_FILE}

    if grep -qwE "#${SWAP_FILE}" /etc/fstab; then
        sed -i "s|#${SWAP_FILE}|${SWAP_FILE}|g" /etc/fstab
    else
        echo "${SWAP_FILE} swap swap defaults 0 0" >> /etc/fstab
    fi

    # Adjust swappiness, default Ubuntu set to 60
    # meaning that the swap file will be used fairly often if the memory usage is
    # around half RAM, for production servers you may need to set a lower value.
    if [[ $(cat /proc/sys/vm/swappiness) -gt 10 ]]; then
        cat >> /etc/sysctl.conf <<EOL
###################################################################
# Custom optimization for LEMPer
#
vm.swappiness=10
EOL
    sysctl -w vm.swappiness=10
    fi
}

function run_silent () {
    # Run the command
    "$@" >/dev/null 2>&1
}

create_db_user () {
    local login_username=$1
    local login_password=$2
    local username=$3
    local password=$4
    local database=$5
    # Create the new user
    mysql -u "$login_username" -p "$login_password" -e "CREATE USER '$username'@'localhost' IDENTIFIED BY '$password';"
    # Grant privileges to the user for the given database
    mysql -u "$login_username" -p "$login_password" -e "GRANT ALL PRIVILEGES ON $database.* TO '$username'@'localhost';"
    # Flush privileges to apply the changes
    mysql -u "$login_username" -p "$login_password" -e "FLUSH PRIVILEGES;"
}

import_db_from_url() {
  # Set the database variables
  local db_url=$1
  local db_user=$2
  local db_password=$3
  local db_name=$4

  # Download the database file
  wget "$db_url" -O database.sql

  # Import the database
  mysql -u "$db_user" "-p$db_password" "$db_name" < database.sql

  # Remove the database file
  rm database.sql
}
 
 issue_ssl () {
    certbot --nginx -d "$1" -d www."$1"
 }


