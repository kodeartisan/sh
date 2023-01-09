#!/usr/bin/env bash

progress_message "Updating repository, please wait"

apt-get update -qq -y && apt-get upgrade -qq -y

progress_message "Installing packages, be patient"

apt-get install -qq -y \
    apt-transport-https apt-utils autoconf automake bash build-essential ca-certificates \
    cmake cron curl dmidecode dnsutils gcc geoip-bin geoip-database gettext git gnupg2 \
    htop iptables libc-bin libc6-dev libcurl4-openssl-dev libgd-dev libgeoip-dev libgpgme11-dev \
    libsodium-dev libssl-dev libxml2-dev libpcre3-dev libtool libxslt1-dev locales logrotate lsb-release \
    make net-tools openssh-server openssl pkg-config python3 re2c rsync software-properties-common \
    sasl2-bin snmp sudo sysstat tar tzdata unzip wget whois xz-utils zlib1g-dev supervisor

progress_message "Reconfigure locale"

locale-gen --purge en_US.UTF-8 id_ID.UTF-8

progress_message "Reconfigure server clock..."

# Reconfigure timezone.
if [[ -n ${TIMEZONE} && ${TIMEZONE} != "none" ]]; then
    echo "${TIMEZONE}" > /etc/timezone
    rm -f /etc/localtime
    dpkg-reconfigure -f noninteractive tzdata

fi

success_message "Required packages installation completed"

# Reconfigure timezone.