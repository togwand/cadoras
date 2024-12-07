{
  description = "flake for togwand/cadoras";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
	treefmt-nix = {
	  url = "https://github.com/numtide/treefmt-nix";
	  inputs.nixpkgs.follows = "nixpkgs";
	};
  };
  outputs = { nixpkgs, treefmt-nix, ... }:
    let
      system = "x86_64-linux";
      treefmt = treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix;
    in
    {
      formatter.${system} = treefmt.config.build.wrapper;
	  # the nix derivation for this app
    };
}
