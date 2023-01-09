#!/usr/bin/env bash

question_message() {
    QUESTION_ICON=$(echo "$(tput setaf 2)"⚡ "$(tput sgr0)")
    echo "$(tput bold)"$QUESTION_ICON $1"$(tput sgr0)"
}

progress_message() {
   echo "🚛  $1... ☕"
   
}

error_message() {
  echo "❌ $1"
   
}

info_message() {
  echo "🚧 $1"
   
}

success_message() {
   echo "🚀 $1"
   
}

throw_error() {
   error_message "$1"
   exit 1   
}

throw_info() {
   info_message "$1"
   exit 1   
}
