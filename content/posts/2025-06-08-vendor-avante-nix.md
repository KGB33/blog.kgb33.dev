---
title: "Avante.nvim + Home-Manager"
date: 2025-06-08T00:00:00-07:00
tags: ["nix", "nvim"]

draft: false
---

How to vendor and patch [avante.nvim](https://github.com/yetone/avante.nvim), when 
configuring Neovim using home manager. 

<!--more-->

The straight forward way to install and configure Avante using home manager is to simply add 
it to the 

```nix
{
  pkgs,
  lib,
  ...
}: {
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      {
        plugin = avante-nvim;
        config = builtins.readFile ./plugins/avante.lua;
        type = "lua";
      }
    ];
  };
}
```

While this works, it also has a few rough edges. First, the nixpkgs version of
Avante is only update when a new version of Avante is released on GitHub.
However, Avante only releases new versions when the rust-subsection is changed.
Lua-only features like new providers don't get a release, and its expected that
users install from main. Second, whenever a new instance of Neovim is opened,
Avante prints debug logs complaining about not being loaded by Lazy (another
Neovim plugin manager), and having to use the default `vim.keymap.set` API.

We are going to fix both of these by vendoring the [Nix package definition for
Avante](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/editors/vim/plugins/non-generated/avante-nvim/default.nix).


# Basic Vendoring

To start, copy the above file from nixpkgs to `nvim/avante.nix`. You'll have to
clean up some of the inputs, I only kept `lib` and `pkgs`. Some functions (like
`vimUtils.buildVimPlugin`) will need to change (to
`pkgs.vimUtils.buildVimPlugin`).

Then, in the file containing your Neovim Config:

```nix
{
  pkgs,
  lib,
  ...
}: let
  avanteOverride = import ./avante.nix {
    pkgs = pkgs;
    lib = lib;
  };
in {
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      {
        plugin = avanteOverride;
        type = "lua";
        config = builtins.readFile ./plugins/avante.lua;
      }
    ];
  };
}
```


# Updating

Just update the `rev` to whatever commit hash you want, set the hash to an
empty string and attempt to build. It will fail with an SHA match error, copy
the expected SHA into the hash field and build successfully.

# Removing Annoying Debug Lines

This one is great; just remove the problem lines in the source using sed!

In `avante.nix` add a `postPatch` step to the `pkgs.vimUtils.buildVimPlugin`:

```nix
  pkgs.vimUtils.buildVimPlugin {

    postPatch = ''
      # Remove the specific debug lines
      find . -name "*.lua" -exec sed -i '/M\.debug.*lazy\.nvim is not available/d' {} \;
      find . -name "*.lua" -exec sed -i '/Utils\.debug.*Setting up avante colors/d' {} \;
    '';

  };
```
