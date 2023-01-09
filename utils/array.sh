#!/usr/bin/env bash

in_array() {
  local needle=$1  # Get the needle (element to search for) from the first argument
  shift  # Shift the arguments to the left, so the haystack (array) is now at $1
  local haystack=("$@")  # Create an array from the remaining arguments
  # Use the grep command to search for the needle in the haystack
  if grep -q "$needle" <<< "${haystack[*]}"; then
    return 0  # Return 0 (true) if the needle is found
  else
    return 1  # Return 1 (false) if the needle is not found
  fi
}

# Example usage:
# array=(1 2 3 2 4 5 2)
# unique_array=$(array_unique "${array[@]}")
array_unique() {
  # Create an empty array to store the unique elements
  local unique=()
  # Use the sort and uniq commands to remove duplicates from the array passed as arguments
  unique=($(sort <<< "$@" | uniq))
  echo "${unique[@]}"  # Return the unique array
}

# Example usage:
# array=(1 2 3 4 5)
# reversed_array=$(reverse "${array[@]}")
array_reverse() {
    local array=("$@")  # Create an array from the arguments passed to the function
  # Use the tac command to reverse the elements in the array
  echo "$(tac <<< "${array[*]}")"  # Return the reversed array
}
