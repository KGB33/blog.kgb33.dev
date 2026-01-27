---
title: "Configuring Neovim with fennel and home-manager"
date: "2025-12-23"
tags: ["nix", "home-manager", "neovim", "fennel"]

draft: false
---

Home manager is a dotfiles manager that declaratively manages your configs using Nix.

One of the many programs that Home manager can configure is Neovim; it can even trivially install
plugins, LSPs, and formatters, no lazy/mason/whatever needed.

The below config installs Telescope, and adds/configures `nvim-lspconfig` using Lua.

```nix
{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      telescope-nvim
      {
        plugin = nvim-lspconfig;
        config = builtins.readFile ./nvim/plugins/lspconfig.lua;
        type = "lua";
      }
    ];
  };
}
```

Note the `type = "lua";` attribute; it accepts your standard `lua` and `viml`,
but we're more interested in the more lispy option: `fennel`.

```nix
  type = mkOption {
        type = types.either (types.enum [
          "lua"
          "viml"
          "teal"
          "fennel"
        ]) types.str;
        description = "Language used in config. Configurations are aggregated per-language.";
        default = "viml";
      };
```

But, if we scroll down in that same file
([`modules/programs/neovim.nix`](https://github.com/nix-community/home-manager/blob/release-25.11/modules/programs/neovim.nix)),
it only automatically combines and adds `config` values for plugins configured
with Lua or Vimscript. it just, silently ignores plugin configs with type
`fennel` or `teal`. That's fair - only Vimscript and Lua are first-party
options, but its still a little disappointing.


We can do it ourselves though using
[Hotpot](https://github.com/rktjmp/hotpot.nvim) and
`programs.neovim.plugins._.runtime`. The latter allows us to add files to
Neovim's runtime directory. While Hotpot will automagically enable `require`-ing any fennel
files in `<runtimepath>/fnl/` directory as-if they were Lua files. 

So, our plugin array changes to: 

```nix
plugins = with pkgs.vimPlugins; [
  {
    plugin = telescope-nvim;
    type = "fennel";
    runtime."fnl/telescopeOptions.fnl".text = builtins.readFile ./nvim/fnl/telescope.fnl;
  }
  {
    plugin = hotpot-nvim;
    config = let
      requireables =
        config.programs.neovim.plugins
        |> builtins.filter (p: p.type == "fennel")
        |> builtins.concatMap (p: builtins.attrNames p.runtime)
        |> builtins.map (rtf: lib.removeSuffix ".fnl" (builtins.baseNameOf rtf));
    in
      ''
        require("hotpot")
      ''
      + lib.concatStrings (map (name: "require(\"${name}\")\n") requireables);
    type = "lua";
  }
];
```

The Hotpot configuration simply gets the names of all the fennel runtime files,
and requires them in `init.lua`. Additionally, the plugin order only affects
the order that the Lua configs are concatenated into `init.lua`. Nix will
correctly resolve the `requireables` array - without infinite recursion - every
time.

> Note: You cannot name your runtimedir fennel file the same name as the plugin!
> `require("telescope")` will load the plugin, not your config for it.

For non-plugin configuration, you can add them to Hotpot's `runtime` attribute, then manually add them to `requireables`. Just make sure `hotpot` is required first!

```nix
{
  plugin = hotpot-nvim;
  runtime."fnl/options.fnl".text = builtins.readFile ./nvim/fnl/options.fnl;
  config = let
    requireables =
      ["hotpot" "options"]
      ++ (config.programs.neovim.plugins
        |> builtins.filter (p: p.type == "fennel")
        |> builtins.concatMap (p: builtins.attrNames p.runtime)
        |> builtins.map (p':
          p'
          |> builtins.baseNameOf
          |> lib.removeSuffix ".fnl"));
  in
    lib.concatStrings (map (name: "require(\"${name}\")\n") requireables);
  type = "lua";
}
```

