{ pkgs? import <nixpkgs> {}}:

pkgs.runCommand "cadoras" {
  # nativeBuildInputs = with pkgs; [];
} builtins.readFile ./cadoras.sh

pkgs.writeShellApplication  {
 name = "cadoras";
 # runtimeInputs = with pkgs; [];
 test = builtins.readFile ./cadoras.sh;
} 
