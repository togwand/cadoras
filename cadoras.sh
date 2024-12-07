#!/usr/bin/env bash
any-key() {
  echo -e "$1"
  read -rsn 1 -p "Press any key to continue"
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
  echo -e "Do $1 as $USER?\n"
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
    *) run "$command" ;;
  esac
}

read-args() {
  echo -e "COMMAND\t\t\tARGUMENTS"
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

header() {
  cat << EOF
CADORAS
 Press 'h' for help

STATUS
 User: $USER
 Location: $PWD

EOF
}

system-menu() {
  cat << EOF
SYSTEM MENU
 1) Collect garbage
 2) Optimise store

EOF
  o1() {
    read-args "nix-collect-garbage" "-d"
  }
  o2() {
    run "nix store optimise"
  }
}

flake-menu() {
  cat << EOF
FLAKE MENU
 1) Update
 2) Build NixOS config
 3) Build ISO

EOF
  o1() {
    if is-user
    then
      run "nix flake update"
    fi
  }
  o2() {
    build-config() {
      read -rei "switch" -p "mode: " mode
      read -rei "." -p "uri: " flake_uri
      read -rei "$HOSTNAME" -p "name: " name
      read-args "nixos-rebuild $mode --flake $flake_uri#$name" "" confirm
    }
    if is-root
    then
      build-config
    fi
  }
  o3() {
    build-iso() {
      read -rei "github:togwand/nixos-config/experimental" -p "uri: " flake_uri
      read -rei "minimal_iso" -p "name: " config_name
      nix build "$flake_uri"#nixosConfigurations."$config_name".config.system.build.isoImage
    }
    if is-root
    then
      confirm "build-iso"
    fi
  }
}

git-menu() {
  cat << EOF
GIT MENU
 1) Format
 2) Full diff
 3) Send changes
 4) Switch branch and merge with current
 5) Custom args

EOF
  o1() {
    if is-user
    then
      run treefmt
    fi
  }
  o2() {
    full-diff() {
      git add --all
      git diff HEAD|bat
    }
    if is-user
    then
      run "full-diff"
    fi
  }
  o3() {
    send-changes() {
      git add --all
      git commit
      git push
    }
    if is-user
    then
      confirm "send-changes"
    fi
  }
  o4() {
    switch-merge() {
      local current_branch
      current_branch="$(git branch --show-current)"
      echo "[BRANCHES]"
      git branch
      read -rei "base" -p "switch to: " next_branch
      git switch "$next_branch"
      git merge "$current_branch"
      echo "switched to $next_branch and merged with $current_branch"
    }
    if is-user
    then
      confirm "switch-merge"
    fi
  }
  o5() {
    read-args "git" ""
  }
}

misc-menu() {
  cat << EOF
MISC MENU
 1) Custom command
 2) Burn iso image

EOF
  o1() {
    read-cmd ""
  }
  o2() {
    burn-iso() {
      lsblk
      read -re -p "device: " burnt
      wipefs -a /dev/"$burnt"
      read -rei "result/iso" -p "path to iso: " iso_path
      cp "$iso_path/nixos-*.iso" "/dev/$burnt"
      sync "/dev/$burnt"
    }
    if is-root
    then
      confirm "burn-iso"
    fi
  }
}

new-user () {
  users=$(passwd -Sa|grep P|grep -Eo '^[^ ]+')
  echo "USERS"
  echo -e "$users\n"
  while read -rep "New user: " new_user
  do
    if [[ -z "${new_user}" ]]
    then
      echo "Not a valid input!"
      return 1
    else
      if ! echo "$users"|grep -w "$new_user"
      then
        echo "Not a valid user!"
        return 1
      else
        exec sudo -u "$new_user" bash "${BASH_SOURCE[0]}" $menu
      fi
    fi
  done
}

to-root() {
  exec sudo bash "${BASH_SOURCE[0]}" $menu
}

switch-user() {
  case $USER in
    root) new-user ;;
    *) to-root ;;
  esac
}

change-directory() {
  echo -e "\nDIRECTORIES HERE\n"
  ls --group-directories-first -a1d -- */ 2> /dev/null
  echo
  read-args "cd" "."
}

help() {
  cat << EOF
USAGE
 Simply execute the program as any user by its name
 Use the keybinds below to execute an option
 You can pass the menu as an option: system, flake, git, misc (default: flake)


TIPS
 If asked for confirmation, press Enter (all other keys abort execution)
 You can abort some ongoing commands with CTRL+C


KEYBINDS
 digits
 		Execute the currently displayed menu option by its number (0 equals 10)

 s, S
 		Changes the active menu to the system menu

 f, F
 		Changes the active menu to the flake menu

 g, G
 		Changes the active menu to the git menu

 m, M
 		Changes the active menu to the misc menu, which contains ungrouped commands

 u, U
		Restarts the program with a different user
 		root -> select a user from a list
		other -> change to root

 c, C
 		Change the program directory

 h, H
 		Read about the program usage in a pager screen

 q, Q
		Exit the program


SYSTEM MENU

Collect garbage
 WIP

Optimise store
 WIP


FLAKE MENU

Update
 WIP

Build NixOS config
 WIP

Build ISO
 WIP


GIT MENU

Format
 WIP

Full diff
 WIP

Send changes
 WIP

Switch branch and merge with current
 WIP

Custom args
 WIP


MISC MENU

Custom command
 WIP

Burn iso image
 WIP
EOF
}

stty -echoctl
trap " " SIGINT

menu="flake"
case "$1" in
  system) menu="system" ;;
  flake) menu="flake" ;;
  git) menu="git" ;;
  misc) menu="misc" ;;
esac
shift

while true
do
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
  clear
  header
  case $menu in
    system) system-menu ;;
    flake) flake-menu ;;
    git) git-menu ;;
    misc) misc-menu ;;
  esac
  read -rsn 1 key
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
    10) o10 ;;
    s|S) menu="system" ;;
    f|F) menu="flake" ;;
    g|G) menu="git" ;;
    m|M) menu="misc" ;;
    u|U) run "switch-user" ;;
    c|C) change-directory ;;
    h|H) help|bat ;;
    q|Q) confirm "clear && exit" ;;
  esac
done
