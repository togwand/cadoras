{
  description = "flake for togwand/cadoras";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs =
    { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      system = "x86_64-linux";
    in
    {
      default = (import ./src { inherit pkgs; });
    };
}
