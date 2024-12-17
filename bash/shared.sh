#!/usr/bin/env bash

stty -echoctl
trap " " SIGINT

any-key() {
  echo -e "\n$1"
  read -rsn 1 -p "Press any key to continue"
  echo
}

is-root() {
  if [ "$USER" != "root" ]
  then
    any-key "Root user is required..." ; return 1
  fi
}

is-user() {
  if [ "$USER" = "root" ]
  then
    any-key "Normal user is required..." ; return 1
  fi
}

run() {
  echo
  if ! eval "$1"
  then
    any-key "Error..." ; return 1
  else any-key "Success!"
  fi
}

confirm() {
  echo -e "\nConfirm $1?"
  read -reN 1 key 2> /dev/null
  case $key in
    "$(printf '\r')") run "$@" ;;
    *) return 1 ;;
  esac
}

read-cmd() {
  echo -e "\nCOMMAND"
  read -rei "$1" command
  case $2 in
    confirm) confirm "$command" ;;
    *) run "$command" ;;
  esac
}

read-args() {
  echo -e "\nCOMMAND ARGUMENTS"
  read -rep "$1 " -i "$2" arguments
  if [ "${arguments}" = "" ]
  then
    case $3 in
      confirm) confirm "$@" ;;
      *) run "$@" ;;
    esac
  else
    local full="$1 $arguments"
    case $3 in
      confirm) confirm "$full" ;;
      *) run "$full" ;;
    esac
  fi
}

assert-root() {
  if [ $EUID != 0 ]
  then
    bin_name="${0##*/}"
    echo "This program options require root permissions
Please restart it with elevated permissions (e.g. sudo $bin_name)
    "
    exit
  fi
}

first-menu() {
  if [ -n "$2" ]
  then
    menu=$2
  else menu=$1
  fi
}

o1() { return
}

o2() { return
}

o3() { return
}

o4() { return
}

o5() { return
}

o6() { return
}

o7() { return
}

o8() { return
}

o9() { return
}

o10() { return
}

quit() {
  clear
  exit
}

interface() {
  while true
  do
    clear
    header
    menus "$menu"
    read -rsn 1 key
    unique-keys "$key"
    case $key in
      1) o1 ;;
      2) o2 ;;
      3) o3 ;;
      4) o4 ;;
      5) o5 ;;
      6) o6 ;;
      7) o7 ;;
      8) o8 ;;
      9) o9 ;;
      0) o10 ;;
      h|H) help|less ;;
      q|Q) quit ;;
    esac
  done
}
