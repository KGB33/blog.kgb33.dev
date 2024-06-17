---
title: "Manage custom packages using Nix and Home-Manager"
date: 2024-06-04T00:00:00-07:00
tags: ["nix", "home-manager"]

draft: false
---

TLDR: Use Nix to install and manage your personal packages instead of `build`/`cp`/`chmox +x`.

<!--more-->

I have two custom programs that I use daily, a notification/widget engine
[`nasty`](https://github.com/KGB33/nasty), and a `tmux` session manager
[`hmm`](https://github.com/KGB33/hmm). The development environments for both
are managed using Nix. This post will walk through the process of packaging
`hmm` (a Haskell program) using Nix flakes, then adding it as an input to my
Home Manager config.

# Packaging `hmm`

This part was really easy, I generated a template (from Serokell's ["Practical
Nix Flakes"](https://serokell.io/blog/practical-nix-flakes#haskell-(cabal))
article) then changed/removed parts I didn't need. 

```nix
{
  description = "Haskell Mux Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        haskellPackages = pkgs.haskellPackages;
        packageName = "hmm";
      in
      {
        packages.${packageName} = haskellPackages.callCabal2nix packageName self rec { }

        packages.default = self.packages.${system}.${packageName};
        defaultPackage = self.packages.${system}.default;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            haskellPackages.haskell-language-server
            ghcid
            cabal-install
          ];
        };
        devShell = self.devShells.${system}.default;
      });
}
```

Then check if it builds:

```shell
$ nix build
$ ./result/bin/hmm --help

Usage: hmm [-r|--repo REPO] [-b|--branch BRANCH]

  prog Desc

Available options:
  -r,--repo REPO           First part of the tmux session name.
  -b,--branch BRANCH       Second part of the tmux session name.
  -h,--help                Show this help text
```

Great, now let's add this flake as a dependency to home-manager.

# Home Manager Dependencies

The pattern to pull in our `hmm` flake is the same as any other flake. First, add it as
an input to `~/.config/home-manager/flake.nix`.

```nix
{
  description = "Home Manager configuration of kgb33";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dagger = {
      url = "github:dagger/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hmm = {
      url = "github:KGB33/hmm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, dagger, hmm, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      dagPkgs = dagger.packages.${system};
      hmm' = hmm.packages.${system}.hmm;
    in
    {
      homeConfigurations."kgb33" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          ./home.nix
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = { inherit dagPkgs hmm'; };
      };
    };
}
```

> Note: I pulled the `hmm` package out of the `hmm` repository using `hmm' = hmm.packages.${system}.hmm`.

Now, to actually install `hmm` edit `home.nix` (heavily truncated here):

```nix
{ config, pkgs, lib, dagPkgs, hmm', ... }:

{
  home.packages = with pkgs; [
    brightnessctl
    grim
    nh
    slurp
    noto-fonts-color-emoji
    (nerdfonts.override { fonts = [ "FiraCode" ]; })
  ] ++ [ dagPkgs.dagger hmm' ];
}
```

Now, to update the `hmm` in my `$PATH` all I have to do is:
  - Push the new commit to the `main` branch.
  - Rum `nix flake update` & `home-manager switch`

Plus, I don't even need to have the `hmm` repo cloned locally!
