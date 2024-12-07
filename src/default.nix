{
  pkgs ? import <nixpkgs> { },
}:
pkgs.writeScriptBin "cadoras" "${builtins.readFile ./script.sh}"
