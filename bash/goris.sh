#!/usr/bin/env bash

if [ -e ./shared.sh ] 2> /dev/null
then
  . ./shared.sh
fi

header() {
  echo "GORIS

STATUS
 Location: $PWD

INFO
 Press 'h' for help
 A flake-uri with a disko module is required
 This program doesn't execute after installing (e.g. no passwd)
  "
}

nixos-menu() {
  echo -ne "NIXOS MENU
 1) Use an existing flake
 2) Clone a flake git repository and edit it
  \r"
  flake-install() {
    read -rei "stale" -p "config name: " config_name
    read-args "disko" "-m disko -f $flake_uri#$config_name" confirm &&
    read-args "nixos-install" "--root /mnt --flake $flake_uri#$config_name --no-root-password " confirm &&
    any-key "Finished! You can reboot now. Remember to sudo nixos-enter and passwd"
  }
  o1() {
    echo
    read -rei "github:togwand/nixos/experimental" -p "flake uri: " flake_uri
    flake-install
  }
  o2() {
    clone-flake() {
      if
      echo
      read -rei "https://github.com/togwand/nixos" -p "git repo to clone: " repo
      read -rei "experimental" -p "git branch to use: " branch
      read -rei "nixos" -p "clone name: " clone_name
      read -rei "/tmp" -p "clone root directory: " clone_path
      echo
      flake_uri="$clone_path/$clone_name"
      git clone "$repo" "$flake_uri" &&
      cd "$flake_uri" &&
      git switch "$branch" &> /dev/null &&
      lf
      then
        echo
        flake-install
      else
        any-key "Couldn't clone flake..." ; return 1
      fi
    }
    clone-flake
  }
}

menus() {
  case $menu in
    nixos) nixos-menu ;;
  esac
}

unique-keys() {
  case $1 in
    n|N) menu="nixos" ;;
  esac
}

help() {
  echo "USAGE
 Use the keybinds below to execute an option

TIPS
 If asked for confirmation, press Enter (all other keys abort execution)

KEYBINDS
 n: Changes the active menu to the (expanded) letter menu (e.g. n = nixos)
 digits: Execute the currently displayed menu option by its number (0 equals 10)
 h: Read about the program usage in an optional pager screen
 q: Quit the program
  "
}

assert-root
first-menu "nixos" "$@"
interface
