#!/usr/bin/env bash

generate_random_username() {
  # Set the characters that can be used in the random string
  local chars='abcdefghijklmnopqrstuvwxyz0123456789'
  # Set the length of the random string
  local length=$1
  # Initialize the random string to be empty
  local random_string=''
  # Use a for loop to generate the random string
  for (( i=0; i<length; i++ )); do
    # Use the $RANDOM variable to select a random character from the list of characters
    random_string+=${chars:$(($RANDOM % ${#chars})):1}
  done
  # Return the random string
  echo "$random_string"
}
