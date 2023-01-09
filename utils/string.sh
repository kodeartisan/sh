#!/usr/bin/env bash

#string="This is a test string"
#result=$(snake_case "$string")
function str_snake_case() {
  # Convert the string to lowercase
  local str="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  # Replace spaces and hyphens with underscores
  str="$(sed 's/[ -]/_/g' <<< "$str")"
  # Remove any remaining non-alphanumeric characters
  echo "$(sed 's/[^a-z0-9_]//g' <<< "$str")"
}

#string="This is a test string"
#result=$(kebab_case "$string")
function str_kebab_case() {
  # Convert the string to lowercase
  local str="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  # Replace spaces with hyphens
  str="$(sed 's/ /-/g' <<< "$str")"
  # Remove any remaining non-alphanumeric characters
  str="$(sed 's/[^a-z0-9-]//g' <<< "$str")"

  # Return the modified string
  echo "$str"
}

#string="This is a test string"
#result=$(str_camel_case "$string")
function str_camel_case {
  # Use sed to replace all non-letter characters with a single space
  local spaced=$(echo "$1" | sed -E 's/[^[:alpha:]]+/ /g')

  # Use sed to replace the first character of each word with its uppercase version
  local capitalized=$(echo "$spaced" | sed -E 's/\b[a-z]/\U&/g')

  # Use sed to remove all spaces
  echo "$capitalized" | sed -E 's/[[:space:]]//g'
}

function str_slug() {
  string=$1

  # Replace spaces with hyphens
  slug=$(echo "$string" | tr ' ' '-')

  # Remove all non-alphanumeric characters
  slug=$(echo "$slug" | sed -E 's/[^[:alnum:]]+//g')

  # Lowercase the slug
  slug=$(echo "$slug" | tr '[:upper:]' '[:lower:]')

  # Return the slug
  echo "$slug"
}

# 
#if str_contains "hello world" "world"; then
function str_contains {
  if grep -q "$2" <<< "$1"; then
    return 0  # Return "true"
  else
    return 1  # Return "false"
  fi
}

function str_length() {
  string=$1

  # Count the number of characters
  characters=$(echo -n "$string" | wc -m)

  # Return the character count
  echo "$characters"
}

function append_to_file () {
  # $1 is the file name
  # $2 is the string to append
  echo "$2" >> $1
}

