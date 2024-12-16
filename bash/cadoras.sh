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
        *) any-key "\nNot a valid user..." && return 1
      esac ;;
    *) run restart ;;
  esac
}

quit() {
  clear && exit
}

system-menu() {
  echo "SYSTEM MENU
 1) Collect garbage
 2) Optimise store
 3) Rebuild NixOS
  "
  o1() {
    read-args "nix-collect-garbage" "-d" confirm
  }
  o2() {
    read-cmd "nix store optimise" confirm
  }
  o3() {
    rebuild-nixos() {
      read -rei "switch" -p "mode: " mode
      read -rei "." -p "uri: " flake_uri
      read -rei "$HOSTNAME" -p "name: " name
      echo
      read-args "nixos-rebuild" "$mode --flake $flake_uri#$name" confirm
    }
    if is-root
    then
      rebuild-nixos
    fi
  }
}

dev-menu() {
  echo "DEV MENU
 1) Treefmt
 2) Full diff
 3) Send changes
 4) Switch branch and merge with current
 5) Setup new repo
  "
  o1() {
    if is-user
    then
      read-args "treefmt" ""
    fi
  }
  o2() {
    full-diff() {
      read-args "git add" "--all" confirm
      read-args "git diff" "HEAD" confirm
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
      echo "BRANCHES"
      git branch
      read -rei "base" -p "switch to: " next_branch
      echo
      read-args "git switch" "$next_branch" confirm
      read-args "git merge" "$current_branch" confirm
    }
    if is-user
    then
      switch-merge
    fi
  }
  o5() {
    setup-new-repo() {
      local directory=${PWD##*/}
      read-args "git init" "" confirm
      read-args "git remote" "add origin https://github.com/togwand/$directory" confirm
    }
    if is-user
    then
      setup-new-repo
    fi
  }
}

flake-menu() {
  echo "FLAKE MENU
 1) Update
 2) Build output
 3) Build ISO
  "
  o1() {
    if is-user
    then
      read-cmd "nix flake update" confirm
    fi
  }
  o2() {
    build-output() {
      read -rei "." -p "uri: " flake_uri
      read -rei "^*" -p "output: " output
      echo
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
      echo
      read-args "nix build" "$flake_uri#nixosConfigurations.$name.config.system.build.isoImage" confirm
    }
    if is-user
    then
      build-iso
    fi
  }
}

rclone-menu() {
  echo "RCLONE MENU
 1) Clone remote
 2) Sync to remote
  "
  o1() {
    clone-remote() {
      echo "REMOTES"
      rclone listremotes
      remotes=$(rclone listremotes)
      echo
      read -rei "collection" -p "shared directory: " dir
      read -rep "local root: " local
      read -rei "$remotes" -p "remote root: " remote
      echo
      read-args "rclone copy" "$remote$dir $local$dir -vi" confirm
    }
    if is-user
    then
      clone-remote
    fi
  }
  o2() {
    sync-to-remote() {
      echo "REMOTES"
      rclone listremotes
      remotes=$(rclone listremotes)
      echo
      read -rei "collection" -p "shared directory: " dir
      read -rep "local root: " local
      read -rei "$remotes" -p "remote root: " remote
      echo
      read-args "rclone sync" "$local$dir $remote$dir -vi" confirm
    }
    if is-user
    then
      sync-to-remote
    fi
  }
}

misc-menu() {
  echo "MISC MENU
 1) Burn iso image
  "
  o1() {
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
