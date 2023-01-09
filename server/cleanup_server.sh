#!/usr/bin/env bash

progress_message "Cleaning up existing installation"
sleep 1
progress_message "Trying to fix broken packages"

[ -f /var/lib/dpkg/lock ] && rm /var/lib/dpkg/lock
[ -f /var/lib/dpkg/lock-frontend ] && rm /var/lib/dpkg/lock-frontend
[ -f /var/cache/apt/archives/lock ] && rm /var/cache/apt/archives/lock

dpkg --configure -a
apt --fix-broken install -qq -y

progress_message "Cleaning up unnecessary packages"

apt-get autoremove -qq -y && \
apt-get autoclean -qq -y && \
apt-get clean -qq -y


