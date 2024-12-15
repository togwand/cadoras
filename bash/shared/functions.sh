#!/usr/bin/env bash

any-key() {
  echo -e "$1"
  read -rsn 1 -p "Press any key to continue"
  echo "
  "
}

is-root() {
  if [ "$USER" != "root" ]
  then
    any-key "Root user is required..."
    return 1
  fi
}

is-user() {
  if [ "$USER" = "root" ]
  then
    any-key "Normal user is required..."
    return 1
  fi
}

run() {
  if ! eval "$1"
  then
    any-key "\nError..."
    return 1
  else any-key "\nSuccess!"
  fi
}

confirm() {
  echo -e "\nConfirm $1?"
  read -reN 1 key 2> /dev/null
  case $key in
    "$(printf '\r')")
      run "$@"
  esac
}

read-cmd() {
  echo "COMMAND"
  read -rei "$1" command
  case $2 in
    confirm) confirm "$command" ;;
    *)
      echo
      run "$command" ;;
  esac
}

read-args() {
  echo "COMMAND ARGUMENTS"
  read -rep "$1 " -i "$2" arguments
  if [ "${arguments}" = "" ]
  then
    case $3 in
      confirm) confirm "$@" ;;
      *)
        echo
        run "$@" ;;
    esac
  else
    local full="$1 $arguments"
    case $3 in
      confirm) confirm "$full" ;;
      *)
        echo
        run "$full" ;;
    esac
  fi
}

quit() {
  clear && exit
}

