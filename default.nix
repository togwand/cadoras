{ pkgs ? import <nixpkgs> {} }:
pkgs.writeScriptBin "cadoras" "${builtins.readFile src/script.sh}"
