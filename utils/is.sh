#!/usr/bin/env bash

is_folder_exists() {
  if [ -d "$1" ]; then
      return 0 # true
  else
      return 1 # false
  fi
}

is_folder_not_exists() {
  return $(! is_folder_exists "$1")
}

is_file_exists() {
  if [ -e "$1" ]; then
    return 0
  else
    return 1
  fi
}

is_file_not_exists() {
  return $(! is_file_exists "$1")
}

function is_file_contains () {
  # $1 is the file name
  # $2 is the string to search for
  if grep -q "$2" $1; then
    return 0
  else
    return 1
  fi
} 

function is_file_not_contains () {
  return $(! is_file_contains "$1" "$2")
}


is_installed() {
  if which "$1" >/dev/null; then
    return 0
  else
    return 1
  fi
}

is_service_running() {
  if [ "$(pgrep -c "$1")" -gt 0 ]; then
    return 0  # True
  else
    return 1  # False
  fi
}

is_not_installed () {
  return $(! is_installed "$1")
}

is_http_oke () {
  local url=$1
  local status_code=$(curl -s -o /dev/null -w "%{http_code}" $url)
  if [[ $status_code -ge 200 && $status_code -lt 300 ]]; then
    return 0 # true
  else
    return 1 # false
  fi
}

is_http_failed () {
  return $(! is_http_oke "$1")
}

is_username_available () {
  # Check if the user exists
  if getent passwd "$1" > /dev/null 2>&1; then
    # User exists, return false
    return 1
  else
    # User does not exist, return true
    return 0
  fi
}

is_username_not_available () {
  return $(! is_username_available "$1")
}

is_db_exist () {
  local username=$1
  local password=$2
  local database=$3
  local exists=1
  # Check if the database exists
  mysql -u "$username" -p"$password" -e "USE $database" &> /dev/null
  exists=$?
  if [ $exists -eq 0 ]; then
    # Database exists
    return 0
  else
    # Database does not exist
    return 1
  fi
}

is_db_not_exists () {
  return $(! is_username_available "$1" "$2" "$3")
}









