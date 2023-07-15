{
  description = "Nix-flake-based Hugo envionment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    daggerCue.url = "./dagger-cue/";
  };

  outputs = { self, nixpkgs, daggerCue, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
      dagger-cue = daggerCue.defaultPackage.${system};
    in
    {
      devShells."${system}".default = pkgs.mkShell {
        packages = with pkgs; [
          cue
          dagger
          dagger-cue
          hugo
          nodejs # npm
          git
        ];
      };
    };
}
