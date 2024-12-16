header() {
  echo "GORIS
 Press 'h' for help

INFO
 This program doesn't execute commands inside/after the installation (e.g. doesn't passwd)
  "
}

help() {
  echo "USAGE
 Use the keybinds below to execute an option

TIPS
 If asked for confirmation, press Enter (all other keys abort execution)
 If a command doesn't show arguments above it can be modified to add sudo -u (or anything)

KEYBINDINGS
 h: Read about the program usage in an optional pager screen
 q: Quit the program
 digits: Execute the currently displayed menu option by its number (0 equals 10)
  "
}

if [ $EUID != 0 ]
then
  bin_name="${0##*/}"
  echo "This program options require root permissions
Please restart it with elevated permissions (e.g. sudo $bin_name)
  "
  exit
fi

menu() {
  echo "MENU
 1) Install NixOS
  "
  o1() {
    install-nixos() {
      echo "OPTIONS
 1) Clone a remote git flake repository
 2) Use an existing local or remote flake (flake-uri)
      "
      read -rsn 1 flake_option
      case $flake_option in
        1)
          read -rei "https://github.com/togwand/nixos" -p "git repo to clone: " repo
          read -rei "experimental" -p "git branch to use: " branch
          read -rei "nixos" -p "clone name: " clone_name
          read -rei "/tmp" -p "clone root directory: " clone_path
          flake_uri="$clone_path/$clone_name"
          echo
          read-cmd "git clone $repo $flake_uri" confirm
          cd "$flake_uri" || true
          read-cmd "git switch $branch"
          echo "Edit flake before installing?"
          read-cmd "ranger" confirm ;;
        2) read -rei "github:togwand/nixos-config/experimental" -p "flake uri: " flake_uri ;;
        *) any-key "\nAn option is required..." && return 1
      esac

      read -rei "stale" -p "config name to install: " config_name
      echo
      read-args "disko" "-m disko -f $flake_uri#$config_name" confirm
      read-args "nixos-install" "--root /mnt --flake $flake_uri#$config_name --no-root-password " confirm
      confirm "systemctl reboot"
    }
    install-nixos
  }
}

stty -echoctl
trap " " SIGINT

while true
do
  clear
  header
  menu
  read -rsn 1 key
  case $key in
    h|H) help|less ;;
    q|Q) quit ;;
    1) o1 ;;
  esac
done
