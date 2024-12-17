#!/usr/bin/env bash

if [ -e ./functions.sh ] 2> /dev/null
then
  . ./functions.sh 2> /dev/null
fi

header() {
  echo "CADORAS
 Press 'h' for help

STATUS
 User: $USER
 Location: $PWD
  "
}

help() {
  echo "USAGE
 Use the keybinds below to execute an option

TIPS
 If asked for confirmation, press Enter (all other keys abort execution)
 You can abort some ongoing commands with CTRL+C

KEYBINDS
 h: Read about the program usage in an optional pager screen
 u: Restarts the program with a different user
 q: Quit the program
 s, d, f, r, m: Changes the active menu to the (expanded) letter menu (e.g. m = misc, f = flake)
 digits: Execute the currently displayed menu option by its number (0 equals 10)
  "
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
      echo "USERS
$users
      "
      read -rep "New user: " new_user
      case $new_user in
        "$users") run restart ;;
        *) any-key "Not a valid user..." && return 1
      esac ;;
    *) run restart ;;
  esac
}

quit() {
  clear && exit
}

system-menu() {
  echo -ne "SYSTEM MENU
 1) Collect garbage
 2) Optimise store
 3) Rebuild NixOS
  \r"
  o1() {
    read-args "nix-collect-garbage" "-d" confirm
  }
  o2() {
    confirm "nix store optimise"
  }
  o3() {
    rebuild-nixos() {
      read -rei "switch" -p "mode: " mode
      read -rei "." -p "uri: " flake_uri
      read -rei "$HOSTNAME" -p "name: " name
      read-args "nixos-rebuild" "$mode --flake $flake_uri#$name" confirm
    }
    if is-root
    then
      rebuild-nixos
    fi
  }
}

dev-menu() {
  stage-format() {
    git add -A &> /dev/null
    treefmt
  }
  print-status() {
    echo -e "\nGIT STATUS"
    git branch
    git status -s
  }
  echo -ne "DEV MENU
 1) Stage, format and local diff
 2) Send changes
 3) Switch branch
 4) Merge branch with current
 5) Remote diff and pull
 6) Setup new repo
  \r"
  o1() {
    if is-user
    then
      run "stage-format"
      git diff --staged
    fi
  }
  o2() {
    send-changes() {
      print-status
      confirm "git commit"
      print-status
      confirm "git push"
      run "print-status"
    }
    if is-user
    then
      send-changes
    fi
  }
  o3() {
    if is-user
    then
      print-status
      read-args "git switch" "" confirm
      run "print-status"
    fi
  }
  o4() {
    merge-current() {
      local current_branch
      current_branch="$(git branch --show-current)"
      print-status
      read-args "git switch" "$current_branch" confirm
      confirm "git merge $current_branch"
      run "print-status"
      git switch "$current_branch" &> /dev/null
    }
    if is-user
    then
      merge-current
    fi
  }
  o5() {
    diff-pull() {
      local current_branch
      current_branch="$(git branch --show-current)"
      git reset &> /dev/null
      git fetch --all &> /dev/null
      git diff --staged "origin/$current_branch"
      confirm "git pull origin $current_branch"
    }
    if is-user
    then
      diff-pull
    fi
  }
  o6() {
    setup-new-repo() {
      confirm "git init"
      read-args "git remote add origin" "https://github.com/togwand/${PWD##*/}" confirm
      run "print-status"
    }
    if is-user
    then
      setup-new-repo
    fi
  }
}

flake-menu() {
  echo -ne "FLAKE MENU
 1) Update
 2) Build output
 3) Build ISO
  \r"
  o1() {
    if is-user
    then
      confirm "nix flake update"
    fi
  }
  o2() {
    build-output() {
      read -rei "." -p "uri: " flake_uri
      read -rei "^*" -p "output: " output
      read-args "nix build" "$flake_uri#$output" confirm
    }
    if is-user
    then
      build-output
    fi
  }
  o3() {
    build-iso() {
      read -rei "github:togwand/nixos/experimental" -p "uri: " flake_uri
      read -rei "lanky" -p "name: " name
      read-args "nix build" "$flake_uri#nixosConfigurations.$name.config.system.build.isoImage" confirm
    }
    if is-user
    then
      build-iso
    fi
  }
}

rclone-menu() {
  rclone-inputs() {
    remotes=$(rclone listremotes)
    echo -e "\nREMOTES"
    rclone listremotes
    echo
    read -rei "collection" -p "shared directory name: " dir
    read -rei "$remotes" -p "its remote parent directory: " remote
    read -rei "$HOME/" -p "its local parent directory: " local
  }
  echo -ne "RCLONE MENU
 1) Config
 2) Local -> Remote
 3) Remote -> Local
  \r"
  o1() {
    if is-user
    then
      read-args "rclone" "config" confirm
    fi
  }
  o2() {
    local-remote() {
      rclone-inputs
      read -rei "sync" -p "operation: " operation
      read-args "rclone" "$operation $local$dir $remote$dir -vi" confirm
    }
    if is-user
    then
      local-remote
    fi
  }
  o3() {
    remote-local() {
      rclone-inputs
      read -rei "copy" -p "operation: " operation
      read-args "rclone" "$operation $remote$dir $local$dir -vi" confirm
    }
    if is-user
    then
      remote-local
    fi
  }
}

misc-menu() {
  echo -ne "MISC MENU
 1) Burn iso image
  \r"
  o1() {
    burn-iso() {
      burn() {
        wipefs -a /dev/"$burnt"
        dd bs=4M status=progress if="$1" of=/dev/"$burnt" oflag=sync
        sync /dev/"$burnt"
      }
      echo
      lsblk
      echo
      read -re -p "device: " burnt
      if [ ! -b /dev/"$burnt" ]
      then any-key "Not a valid device..." && return 1
      fi
      read -rei result/iso/*.iso -p "iso path: " iso_path
      local found_iso
      found_iso=$(find -- "$iso_path"/*.iso 2> /dev/null)
      if [ -e "$iso_path" ]
      then
        confirm "burn $iso_path"
      else
        if [ -e "$found_iso" ]
        then confirm "burn $found_iso"
        else any-key "Not a valid path..." && return 1
        fi
      fi
    }
    if is-root
    then
      burn-iso
    fi
  }
}

stty -echoctl
trap " " SIGINT

if [ -n "$1" ]
then
  case $1 in
    system) menu="system" ;;
    dev) menu="dev" ;;
    flake) menu="flake" ;;
    rclone) menu="rclone" ;;
    misc) menu="misc" ;;
  esac
else menu="system"
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
    dev) dev-menu ;;
    flake) flake-menu ;;
    rclone) rclone-menu ;;
    misc) misc-menu ;;
  esac
  read -rsn 1 key
  case $key in
    h|H) help|less ;;
    u|U) switch-user ;;
    q|Q) quit ;;
    s|S) menu="system" ;;
    d|D) menu="dev" ;;
    f|F) menu="flake" ;;
    r|R) menu="rclone" ;;
    m|M) menu="misc" ;;
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
  esac
done
