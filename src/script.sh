#!/usr/bin/env bash
any-key() {
  echo -e "$1"
  read -rsn 1 -p "Press any key to continue"
  echo
}

is-root() {
  if [ "$USER" != "root" ]
  then
    any-key "\nRoot user is required..."
    return 1
  fi
}

is-user() {
  if [ "$USER" = "root" ]
  then
    any-key "\nNormal user is required..."
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
  echo -e "\nCOMMAND"
  read -rei "$1" command
case $2 in confirm) confirm "$command" ;;
    *) run "$command" ;;
  esac
}

read-args() {
  echo -e "\nCOMMAND\t\t\tARGUMENTS"
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
    read-args "nix-collect-garbage" "-d" confirm
  }
  o2() {
    read-args "nix store optimise" "" confirm
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
      read-args "nix flake update" "" confirm
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
      read -rei "minimal_iso" -p "name: " name
      read-args "nix build $flake_uri#nixosConfigurations.$name.config.system.build.isoImage" "" confirm
    }
    if is-root
    then
      build-iso
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
      read-args "treefmt" "" confirm
    fi
  }
  o2() {
    full-diff() {
      read-args "git add" "--all" confirm
      read-args "git diff HEAD" "| bat" confirm
    }
    if is-user
    then
      full-diff
    fi
  }
  o3() {
    send-changes() {
      read-args "git add" "--all" confirm
      read-args "git commit" "" confirm
      read-args "git push" "" confirm
    }
    if is-user
    then
      send-changes
    fi
  }
  o4() {
    switch-merge() {
      local current_branch
      current_branch="$(git branch --show-current)"
      echo "[BRANCHES]"
      git branch
      read -rei "base" -p "switch to: " next_branch
      read-args "git switch $next_branch" "&& git merge $current_branch" confirm
    }
    if is-user
    then
      switch-merge
    fi
  }
  o5() {
    if is-user
    then
      read-args "git" ""
    fi
  }
}

rclone-menu() {
  cat << EOF
RCLONE MENU
 1) Clone remote
 2) Sync to remote
 3) Custom args
EOF
  o1() {
    clone-remote() {
      echo -e "REMOTES"
      rclone listremotes
      read -rep "local root: " local
      read -rep "remote root: " remote
      read -rei "collection" -p "shared directory: " dir
      read-args "rclone copy" "$remote$dir $local$dir" confirm
    }
    if is-user
    then
      clone-remote
    fi
  }
  o2() {
    sync-to-remote() {
      echo -e "REMOTES"
      remotes=$(rclone listremotes)
      read -rep "local root: " updated_local
      read -rei "$remotes" -p "remote root: " unsynced_remote
      read -rei "collection" -p "shared directory: " dir
      read-args "rclone sync" "$updated_local$dir $unsynced_remote$dir" confirm
    }
    if is-user
    then
      sync-to-remote
    fi
  }
  o3() {
    if is-user
    then
      read-args "rclone" ""
    fi
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
      burn() {
        wipefs -a /dev/"$burnt"
        dd bs=4M status=progress if="$iso_path/nixos-*.iso" of=/dev/"$burnt" oflag=sync
        sync /dev/"$burnt"
      }
      lsblk
      read -re -p "device: " burnt
      read -rei "result/iso" -p "path to iso: " iso_path
      confirm "burn"
    }
    if is-root
    then
      burn-iso
    fi
  }
}

switch-user () {
  restart() {
    case $USER in
      root) exec sudo -u "$new_user" bash "${BASH_SOURCE[0]}" "$menu" ;;
      *) exec sudo bash "${BASH_SOURCE[0]}" "$menu"
    esac
  }
  case $USER in
    root)
      users=$(passwd -Sa|grep P|grep -Eo '^[^ ]+'|grep -v root)
      echo -e "\nUSERS\n$users\n"
      read -rep "New user: " new_user
      case $new_user in
        "$users") confirm restart ;;
        *) any-key "\nNot a valid user..." && return 1
      esac ;;
    *) confirm restart ;;
  esac
}

change-directory() {
  if ls --group-directories-first -a1d -- */ > /dev/null 2> /dev/null
  then
    echo -e "DIRECTORIES HERE"
    ls --group-directories-first -a1d -- */ 2> /dev/null
    echo
    read-args "cd" ""
  else
    read-args "cd" ".."
  fi
}

help() {
  cat << EOF
USAGE
 Simply execute the program as any user by its name
 Use the keybinds below to execute an option


TIPS
 If asked for confirmation, press Enter (all other keys abort execution)
 You can abort some ongoing commands with CTRL+C
 When changing directories you can autocomplete with TAB


KEYBINDS
 digits
 		Execute the currently displayed menu option by its number (0 equals 10)

 s, S
 		Changes the active menu to the system menu

 f, F
 		Changes the active menu to the flake menu

 g, G
 		Changes the active menu to the git menu

 r, R
 		Changes the active menu to the rclone menu

 m, M
 		Changes the active menu to the misc menu, which contains ungrouped commands

 c, C
 		Change the program directory

 h, H
 		Read about the program usage in an optional pager screen

 u, U
		Restarts the program with a different user
 		root -> select a user from a list
		other -> change to root

 q, Q
		Quit the program


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


RCLONE MENU

Clone remote
 WIP

Sync to remote
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

quit() {
  clear && exit
}

stty -echoctl
trap " " SIGINT

if [ -n "$1" ]
then
  case $1 in
    system) menu="system" ;;
    flake) menu="flake" ;;
    git) menu="git" ;;
    rclone) menu="rclone" ;;
    misc) menu="misc" ;;
  esac
else menu="flake"
fi

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
    rclone) rclone-menu ;;
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
    r|R) menu="rclone" ;;
    m|M) menu="misc" ;;
    c|C) change-directory ;;
    h|H) read-args "help" "| less" confirm ;;
    u|U) switch-user ;;
    q|Q) confirm quit ;;
  esac
done
