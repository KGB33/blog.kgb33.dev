---
title: "Packaging Rust programs with Nix"
pubDate: "2025-06-28"
tags: ["nix", "rust"]

draft: true
---

<!-- 
Rough outline:
  - Intro
  - Whats Nix?
    - Syntax / Flake crash course.

  - The hello world of packaging
  - Leveling up with Crane
    - Checks
    - Comlpex build envs
      - WASI
      - Cross complie?

  - Bonus Bin
    - Dev Shells
    - Script sharing
-->

# Intro

I'm Kel

# What is Nix? 

Nix is a reproducible, declarative package manager; which is configured using a
functional programming language (also called Nix).

The programming language defines **derivations** (basically big JSON files) as
the result of a pure function. The package manager will then take these
derivations and **realize** into *something* - not necessarily a package.

---


A `flake.nix` file is used to collect and expose those functions as outputs. As
well as define the inputs. Additionally, `flake.lock` file is used to pin inputs.

The below flake has:
  - An input: The `nixpkgs` repository, containing "over 120,000" pre-packaged programs.
  - Two outputs: the `hello` package twice.

```nix
{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: {
    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;
  };
}
```

> [!QUESTION] Why might we have to specify what system (`x86_64-linux`) this package is for?

---

The `nix` cli acts as a bridge between the nix code and the nix package manager
(which runs as a daemon). 

To view the inputs of a flake, use `nix flake metadata`

```shell
❯ nix flake metadata
Resolved URL:  git+file:///home/kgb33/Code/SpokaneTechUserGroups/rust/nix-talk
Locked URL:    git+file:///home/kgb33/Code/SpokaneTechUserGroups/rust/nix-talk?rev=9a378ab5123c55641d63341e63a55fe75d7699bc
Description:   A very basic flake
Path:          /nix/store/rqw1gz6jrwpc5jbi1082hc0f72z19fc8-source
Revision:      9a378ab5123c55641d63341e63a55fe75d7699bc
Revisions:     1
Last modified: 2025-07-04 08:26:51
Fingerprint:   9263f16417d59d5989f774ee4630d4620bf0f3190c9d8a549ba2a46e9197b80d
Inputs:
└───nixpkgs: github:nixos/nixpkgs/3016b4b15d13f3089db8a41ef937b13a9e33a8df?narHash=sha256-P/SQmKDu06x8yv7i0s8bvnnuJYkxVGBWLWHaU%2Btt4YY%3D (2025-06-30 08:19:38)
```


---


To view details on a flake, use `nix flake show`.

```shell
❯ nix flake show
git+file:///home/kgb33/Code/SpokaneTechUserGroups/rust/nix-talk?rev=9a378ab5123c55641d63341e63a55fe75d7699bc
└───packages
    └───x86_64-linux
        ├───default: package 'hello-2.12.2'
        └───hello: package 'hello-2.12.2'
```

> Question: Why doesn't this provide `hello` for MacOS? How would you add it?

---

To actually use the outputs, use `nix run` or `nix build` or `nix shell`.

```shell
❯ nix run
Hello, world!

❯ nix build
❯ ./result/bin/hello
Hello, world!

❯ nix shell
❯ hello
Hello, world!
```

> [!INFO] By default, the flake in the current directory is used but you can access remote flakes too. 
> For convince, `nixpkgs` is an alias for `git+https://github.com/NixOS/nixpkgs`.

 ```
❯ nix run nixpkgs#hello
Hello, world!
```

# Basic Packaging

Before we get to packaging a rust project, let's do a super simple bash script.

```bash
#!/bin/sh
echo Hello from my cool script!
```

```nix
{
  description = "A basic flake that packages a bash script";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Grab a package that makes defining flake outputs for multiple systems easier
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
  # This is basically a for-each loop. It lets us define the
  # output for each system once, in the same way, for every system.
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      name = "my-cool-bash-script";
    in {
      packages = {
        default = pkgs.stdenv.mkDerivation {
          pname = name;
          version = "1.0.0";

          # cleanSource is a function that removes common
          # temporary and version control files
          src = pkgs.lib.cleanSource ./.;
          # Note paths are a type.   ^^^

          # Technically, we don't need this.
          # The script shebang uses the system bash, and bash 
          # is included in the installPhase. 
          buildInputs = [pkgs.bash];

          installPhase = ''
            mkdir -p $out/bin
            cp ${name}.sh $out/bin/${name}
            chmod +x $out/bin/${name}
          '';
        };
      };
    });
}
```

---

There is a better, more succinct way to package bash scripts though. 

```nix
{
  description = "A basic flake that packages a bash script";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      myScript = pkgs.writeShellApplication {
        name = "my-cool-bash-script";
        runtimeInputs = with pkgs; [gum];
        # We could read the script from a file
        # text = pkgs.builtins.readFile ./my-cool-bash-script.sh
        text = ''
          gum style \
            --foreground 2 --border-foreground 1 --border double \
            --align center --width 5 --margin "1 2" --padding "2 4" \
            'Hello SRUG'
        '';
      };
    in {
      packages = {
        default = myScript;
      };
    });
}
```

Here the helper function `writeShellApplication` takes a set of inputs and
builds a shell application. It takes care of setting the shebang, sensible
shell settings, and we can include anything in nixpkgs as a dependency. It will
even run ShellCheck on it.

The generated script (via `nix build`) is:

```bash
#!/nix/store/gkwbw9nzbkbz298njbn3577zmrnglbbi-bash-5.3p0/bin/bash
set -o errexit
set -o nounset
set -o pipefail

export PATH="/nix/store/ghqbmfsmdhccms652yx3n0mkj86jlz8r-gum-0.16.2/bin:$PATH"

gum style \
  --foreground 2 --border-foreground 1 --border double \
  --align center --width 5 --margin "1 2" --padding "2 4" \
  'Hello SRUG'
```

> [!CAUTION] Note the absolute paths to `bash` and `gum`.
> This script will only work on systems its been realized on.

# What about Rust?

Just like bash scripts, Rust programs have easy to use build tools. To start, we can use the buildin 
`buildRustPackage` function.

```nix
{
  description = "A simple Crane flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        myCrate = pkgs.rustPlatform.buildRustPackage {
          # This needs to match the package.name entry in cargo.toml
          pname = "srug-nix";
          version = "v0.1.0";

          src = pkgs.lib.cleanSource ./.;
          cargoLock.lockFile = ./Cargo.lock;
        };
      in {
        packages.default = myCrate;
      }
    );
}
```

---

They also have supercharged third party wrappers that make it a breeze to package and test your code.

My preference is [ipelkov/crane](https://github.com/ipetkov/crane).

The package is defined in a let-in block so that they are in scope for the
outputs section of the flake.
```nix
let
  pkgs = nixpkgs.legacyPackages.${system};

  # Initalize Crane funcitons for this system/nixpkgs
  craneLib = crane.mkLib pkgs;

  commonArgs = {
    # Crane has a specallised clean source funciton
    src = craneLib.cleanCargoSource ./.;
    strictDeps = true;

    # On nix, most packages need `pkg-config` for linkning, and `openssl` if its
    # a webserver. Our hello world is too simple to need them.
    buildInputs = [
            pkgs.pkg-config pkgs.openssl
        ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [pkgs.libiconv];
    # the `++` syntax appends arrays
  };

  # Here, our package is build by passing an attibute set to crane's
  # build package funciton. `//` merges attr sets.
  srug-nix = craneLib.buildPackage (
    commonArgs
    // {
      # Why might we have this line?
      cargoArtifacts = craneLib.buildDepsOnly commonArgs;
    }
  );
in
```

---

Within the output section of the flake, we use the `srug-nix` package:

In addition to the `packages` section that we had in the previous examples, we
also define two more sections, `checks` and `devShells`.

```nix
{
  checks = {
    inherit srug-nix;
  };

  packages.default = srug-nix;

  devShells.default = craneLib.devShell {
    checks = self.checks.${system};

    packages = [
      rust-analyser
    ];
  };
}
```

The flake's `checks` output inherits the checks that crane created for our
package, and the checks are run via `nix flake check`. In this case, the checks
are fairly simple, think `cargo test` and clippy.

`devShells` is one of my favorite features of nix, it lets you defined an
environment and package set to have available for a project. This program is
pretty simple, so we don't need much.

`devShells` are great when working on a team or project that requires multiple
command line tools or a specific version of a language. For example, my
homelab's IaC repo has a flake with just a `devShell` output that contains all
the various CLIs I need for the project. Likewise, at work, our mono-repo
contains all the various tooling that we need, and a customized build of PHP,

```nix
{
  devshells.default = pkgs.mkShell {
    packages = [
      (php84.buildEnv {
        extraConfig = ''
          memory_limit = 2G
        '';
        extensions = {
          enabled,
          all,
        }:
          enabled
          ++ (with all; [
            # xdebug
          ]);
      })
      _1password-cli
      colima
    ];
  };
}
```

To use these `devShells`, you can run `nix develop`, which will always drop you
into a bash shell. Then, if you want to use non-bash shells, you can use
`direnv` to keep your shell and all the associated customization.

# Using your packaged code

To use an application packaged with nix, you just include it as an input in
your flake, then you can use it like you would any package from `nixpkgs`.

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hmm = {
      url = "github:KGB33/hmm";
      imports.nixpkgs.follows = "nixpkgs";
    };
  };
  ouputs = {
    nixpkgs,
    hmm,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      hmm' = hmm.packages.${system}.hmm;
    in {
      devShells.default = pkgs.mkShell {packages = [hmm'];};
    });
}
```
