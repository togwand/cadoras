#!/usr/bin/env bash

if [ -e ./shared.sh ] 2> /dev/null
then
  . ./shared.sh
fi

header() {
  echo "CADORAS

STATUS
 User: $USER
 Location: $PWD

INFO
 Press 'h' for help
  "
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
      echo
      read -rei "test" -p "mode: " mode
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
  echo -ne "DEV MENU
 1) Status, format, stage all and local diff
 2) Send changes
 3) Switch and merge changes to another branch
 4) Remote diff and pull
 10) Setup new repo
  \r"
  print-status() {
    echo -e "\nGIT STATUS"
    git branch
    git status -s
  }
  o1() {
    if is-user
    then
      print-status
      git add -A &> /dev/null
      echo
      treefmt
      git add -A &> /dev/null
      confirm "git diff --staged"
    fi
  }
  o2() {
    send-changes() {
      print-status
      confirm "git commit"
      confirm "git push"
    }
    if is-user
    then
      send-changes
    fi
  }
  o3() {
    switch-merge() {
      local current_branch
      current_branch="$(git branch --show-current)"
      print-status
      read-args "git switch" "" confirm && confirm "git merge $current_branch" && git switch "$current_branch" &> /dev/null
    }
    if is-user
    then
      switch-merge
    fi
  }
  o4() {
    diff-pull() {
      local current_branch
      current_branch="$(git branch --show-current)"
      git reset &> /dev/null
      git fetch --all &> /dev/null
      confirm "git diff --staged origin/$current_branch" &&
      read-args "git pull" "origin $current_branch --rebase=false" confirm
    }
    if is-user
    then
      diff-pull
    fi
  }
  o10() {
    setup-new-repo() {
      confirm "git init" && read-args "git remote add origin" "https://github.com/togwand/${PWD##*/}" confirm
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
      echo
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
      echo
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
  echo -ne "RCLONE MENU
 1) Config
 2) Local -> Remote
 3) Remote -> Local
  \r"
  rclone-inputs() {
    remotes=$(rclone listremotes)
    echo -e "\nREMOTES"
    rclone listremotes
    echo
    read -rei "collection" -p "shared directory name: " dir
    read -rei "$remotes" -p "its remote parent directory: " remote
    read -rei "$HOME/" -p "its local parent directory: " local
  }
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

menus() {
  case $menu in
    system) system-menu ;;
    dev) dev-menu ;;
    flake) flake-menu ;;
    rclone) rclone-menu ;;
  esac
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
      echo "
USERS
$users
      "
      read -rep "New user: " new_user
      case $new_user in
        "$users") run restart ;;
        *) any-key "Not a valid user..." ; return 1
      esac ;;
    *) run restart ;;
  esac
}

unique-keys() {
  case $1 in
    u|U) switch-user ;;
    s|S) menu="system" ;;
    d|D) menu="dev" ;;
    f|F) menu="flake" ;;
    r|R) menu="rclone" ;;
  esac
}

help() {
  echo "USAGE
 Use the keybinds below to execute an option

TIPS
 If asked for confirmation, press Enter (all other keys abort execution)

KEYBINDS
 u: Restarts the program with a different user
 s, d, f, r: Changes the active menu to the (expanded) letter menu (e.g. d = dev, r = rclone)
 digits: Execute the currently displayed menu option by its number (0 equals 10)
 h: Read about the program usage in an optional pager screen
 q: Quit the program
  "
}

first-menu "dev" "$@"
interface
