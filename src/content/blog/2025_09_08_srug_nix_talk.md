---
title: "Packaging Rust programs with Nix"
pubDate: "2025-06-28"
tags: ["nix", "rust"]

draft: false
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

# What is Nix? 

Nix is a functional DSL designed to define **derivations** from a set of
inputs. The implementation (also called `nix`) then **realizes** these
derivations into artifacts.

---

# Nix Crash Course

```nix
# crashCourse.nix
{...}: let
  # Variables are defined in let-in blocks

  # All functions are unary, but attr sets can be unpacked.
  # The `...` ignores other attributes (if any)
  mult = {x, y ? 2, ...}: x * y;
  tripler = x: mult { x = x; y = 3;};
in {
  # Parentheses are not needed when calling functions.
  doubled = mult {x = 4;};
  tripled = tripler 6;
  # But are still used to group expressions
  quadrupled = (x: mult {x = x; y = 4}) 2;
  
  # An "attribute set" is the basic building block for
  # all nix expressions.
  bar = {
    thisIs = "an attr set";
    somePath = ./src/main.rs;
    lists = ["are" "space" "seperated"];
  };
}
```

---

# How Do I use it

A common 'entry-point' for a nix expression is a "nix flake".

> Nix flakes provide a standard way to write Nix expressions (and therefore
> packages) whose dependencies are version-pinned in a lock file. [...] A flake
> refers to a file-system tree whose root directory contains the Nix file
> specification called `flake.nix`.

---

# Flake Overview

A flake has four sections, `description`, `inputs`, `outputs`, `nixConfig`.

Anything and everything (except the file-system tree containing the
flake**) that is used in the flake must be in the inputs attribute.

`outputs` is a function that takes the inputs as parameters and returns an attribute set.
This attribute set has several standard attributes, the most common is `packages`.

```nix
{
  description = "A super basic Flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {self, ...} @ inputs: {
    packages.x86_64-linux.default = inputs.nixpkgs.legacyPackages.x86_64-linux.hello;
  };
}

```

---

The `nix` cli acts as a bridge between flakes and the daemon.

To view the inputs of a flake, use `nix flake metadata`

```shell
❯ nix flake metadata
Resolved URL:  path:/home/kgb33/Code/SpokaneTechUserGroups/rust/nix-talk
Locked URL:    path:/home/kgb33/Code/SpokaneTechUserGroups/rust/nix-talk?lastModified=1761015353&narHash=sha256-Uvz%2BKBBeVB3pDvLOqrVTVx2LAovp3/x3XEKVXSXxcM0%3D
Description:   A super basic Flake
Path:          /nix/store/r9r47ax0frr24ny7c436qjlr9f3s8lb1-source
Last modified: 2025-10-20 19:55:53
Inputs:
└───nixpkgs: github:nixos/nixpkgs/5e2a59a5b1a82f89f2c7e598302a9cacebb72a67?narHash=sha256-K5Osef2qexezUfs0alLvZ7nQFTGS9DL2oTVsIXsqLgs%3D (2025-10-19 12:55:10)
```

To view the outputs of a flake, use `nix flake show`.

```shell
❯ nix flake show
path:/home/kgb33/Code/SpokaneTechUserGroups/rust/nix-talk?lastModified=1761015353&narHash=sha256-Uvz%2BKBBeVB3pDvLOqrVTVx2LAovp3/x3XEKVXSXxcM0%3D
└───packages
    └───x86_64-linux
        └───default: package 'hello-2.12.2'
```


---

To actually use the outputs, use `nix run` or `nix build` or `nix shell` -
depending on the output and what you want to do with it.

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

---

# DevShells

Before we can create a new rust project for us to package, we need to install Cargo.

Nix provides a way to declaratively create a development shell using the `devShells` output.

```nix
{
  description = "A super basic Flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {self, ...} @ inputs: let
    system = "x86_64-linux";
    pkgs = import inputs.nixpkgs {inherit system;};
  in {
    packages."${system}".default = pkgs.hello;

    devShells."${system}".default = pkgs.mkShell {
      packages = with pkgs; [cargo llvm];
    };
  };
}
```

Now, our flake output shows the development shell, and we can activate it using `nix develop`.

```
❯ nix flake show
warning: Git tree '/home/kgb33/Code/SpokaneTechUserGroups/rust/nix-talk' is dirty
git+file:///home/kgb33/Code/SpokaneTechUserGroups/rust/nix-talk
├───devShells
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
└───packages
    └───x86_64-linux
        └───default: package 'hello-2.12.2'


❯ nix develop
```

> [!TIP] Use Direnv to keep your shell / status line. Nix devShells use bash by default.


---

# The Rust Package

We're going to keep the rust package simple, just the default hello world from
`cargo init`.


```shell
❯ cargo run
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.01s
     Running `target/debug/nix-talk`
Hello, world!
```

---

# What about Rust?

Nix has a builtin `buildRustPackage` function, we just need to pass the name,
version, source, and `Cargo.lock`.

```nix
{
  description = "A super basic Flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {self, ...} @ inputs: let
    system = "x86_64-linux";
    pkgs = import inputs.nixpkgs {inherit system;};

    srugNix = pkgs.rustPlatform.buildRustPackage {
      pname = "srug-nix";
      version = "v0.1.0";

      src = pkgs.lib.cleanSource ./.;
      cargoLock.lockFile = ./Cargo.lock;
    };
  in {
    packages."${system}".default = srugNix;

    devShells."${system}".default = pkgs.mkShell {
      packages = with pkgs; [cargo llvm];
    };
  };
}
```
---

Now, let's (try to) run our program using nix: 

```
❯ nix run
warning: Git tree '/home/kgb33/Code/SpokaneTechUserGroups/rust/nix-talk' is dirty
error:
       …(stack trace truncated; use '--show-trace' to show the full, detailed trace)

       error: path '/nix/store/4nr2b0q3z3a6bvqhjglxb2wlbl2habwy-source/Cargo.lock' does not exist

❯ ls /nix/store/4nr2b0q3z3a6bvqhjglxb2wlbl2habwy-source/
 flake.lock   flake.nix

❯ ls .
󰣞 src   target   Cargo.lock   Cargo.toml   flake.lock   flake.nix
```

As part of Nix's functional purity, only files tracked in Git are copyed into
the store, so as far as Nix is concerned, `Cargo.lock` doesn't exist.

```
❯ git add --intent-to-add Cargo.* src/main.rs

❯ nix run
warning: Git tree '/home/kgb33/Code/SpokaneTechUserGroups/rust/nix-talk' is dirty
Hello, world!
```

🎉🎉

---

There are also third party libraries that make more advanced programs easier to package.

My preference is [ipelkov/crane](https://github.com/ipetkov/crane). To use it,
we just need to add it as an input, and update the contents of the `let-in`
block:

```nix
{
  description = "A super basic Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    crane.url = "github:ipetkov/crane";
  };

  outputs = {self, ...} @ inputs: let
    system = "x86_64-linux";
    pkgs = import inputs.nixpkgs {inherit system;};

    crane = inputs.crane.mkLib pkgs;

    src = crane.cleanCargoSource ./.;

    commonArgs = {
      inherit src;
    };

    cargoArtifacts = crane.buildDepsOnly commonArgs;

    srugNix = crane.buildPackage (
      commonArgs // {inherit cargoArtifacts;}
    );
  in {
    packages."${system}".default = srugNix;

    devShells."${system}".default = pkgs.mkShell {
      packages = with pkgs; [cargo llvm];
    };
  };
}
```

---

There are a few upgrades over `buildRustPackage` already. 

`src = crane.cleanCargoSource ./.;` is specialized for Cargo repositories, so
less unneeded files are copied into the store. 


`cargoArtifacts = crane.buildDepsOnly commonArgs;` builds all (zero) of our
dependencies separate step, so they will not be recompiled every build.

Additionally, Crane allows us to easily map CI style checks to our third flake output: `checks`.

---

```nix
{
  inputs = {...};

  outputs = {self, ...} @ inputs: let
    ...
  in {
    packages."${system}".default = srugNix;

    devShells."${system}".default = pkgs.mkShell {
      packages = with pkgs; [cargo llvm];
    };

    checks."${system}" = {
      inherit srugNix;

      clippy = crane.cargoClippy (
        commonArgs
        // {
          inherit cargoArtifacts;
          cargoClippyExtraArgs = "--all-targets -- --deny warnings";
        }
      );

      fmt = crane.cargoFmt {
        inherit src;
      };
    };
  };
}
```

Now, after adding an used variable to `src/main.rs`, we can run `nix flake check`:

```
❯ nix flake show
git+file:///home/kgb33/Code/SpokaneTechUserGroups/rust/nix-talk?ref=refs/heads/main&rev=71365e62ae101ebb1828444d22ea07e6be8514b5
├───checks
│   └───x86_64-linux
│       ├───clippy: derivation 'srug-nix-clippy-0.1.0'
│       ├───fmt: derivation 'srug-nix-fmt-0.1.0'
│       └───srugNix: derivation 'srug-nix-0.1.0'
├───devShells
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
└───packages
    └───x86_64-linux
        └───default: package 'srug-nix-0.1.0'

❯ nix flake check
error: builder for '/nix/store/y7rxcz3f5f355d57rd9l99z7a1ryr8nm-srug-nix-clippy-0.1.0.drv' failed with exit code 101;
       last 25 log lines:
       > +++ command cargo clippy --release --locked --all-targets -- --deny warnings
       >     Checking srug-nix v0.1.0 (/build/source)
       > error: unused variable: `unused_var`
       >  --> src/main.rs:2:13
       >   |
       > 2 |     let mut unused_var = "abc";
       >   |             ^^^^^^^^^^ help: if this is intentional, prefix it with an underscore: `_unused_var`
       >   |
       >   = note: `-D unused-variables` implied by `-D warnings`
       >   = help: to override `-D warnings` add `#[allow(unused_variables)]`
       >
       > error: variable does not need to be mutable
       >  --> src/main.rs:2:9
       >   |
       > 2 |     let mut unused_var = "abc";
       >   |         ----^^^^^^^^^^
       >   |         |
       >   |         help: remove this `mut`
       >   |
       >   = note: `-D unused-mut` implied by `-D warnings`
       >   = help: to override `-D warnings` add `#[allow(unused_mut)]`
       >
       > error: could not compile `srug-nix` (bin "srug-nix" test) due to 2 previous errors
       > warning: build failed, waiting for other jobs to finish...
       > error: could not compile `srug-nix` (bin "srug-nix") due to 2 previous errors
       For full logs, run:
         nix log /nix/store/y7rxcz3f5f355d57rd9l99z7a1ryr8nm-srug-nix-clippy-0.1.0.drv
```

Running a single check directly is often better developer experience. But I've
found that adding the checks to your flake is super convenient to run all of
them at once, especially if you're using nix to build or distribute the final
artifact.

---

# Questions 

---

# Lets Talk `system`

So far, we've been hardcoding `system` to `x86-64-linux`, but Nix works on more
than just run of the mill Linux.

However, because nix is pure, **the current system cannot affect the output of a
flake.** To demonstrate this, let's build our flake for additional systems:

---

```nix
{
  description = "A super basic Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    crane.url = "github:ipetkov/crane";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    forAllSystems = func:
      nixpkgs.lib.genAttrs
      ["x86_64-linux" "aarch64-darwin"] (
        system:
          func (import nixpkgs {inherit system;})
      );
  in {
    packages = forAllSystems (pkgs: let
      crane = inputs.crane.mkLib pkgs;

      src = crane.cleanCargoSource ./.;

      commonArgs = {
        inherit src;
      };

      cargoArtifacts = crane.buildDepsOnly commonArgs;

      srugNix = crane.buildPackage (
        commonArgs // {inherit cargoArtifacts;}
      );
    in {
      default = srugNix;
    });

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [cargo llvm];
      };
    });
  };
}
```

---

The key here is the `forAllSystems` function.

```nix
forAllSystems = func:
  nixpkgs.lib.genAttrs
  ["x86_64-linux" "aarch64-darwin"] (
    system:
      func (import nixpkgs {inherit system;})
  );
```

Its argument is another function `func`, which it uses to populate the
sub-attributes created by `nixpkgs.lib.genAttrs`.

If we manually expand the call to `genAttrs`, the function would look as follows:

```nix
forAllSystems = func: {
    "x86_64-linux" = func (import nixpgks { inherit "x86_64-linux"; });
    "aarch64-darwin" = func (import nixpgks { inherit "aarch64-darwin"; });
}
```

--- 

Now, if we show all the flake output, we can see the Darwin system.

```
❯ nix flake show --all-systems
git+file:///home/kgb33/Code/SpokaneTechUserGroups/rust/nix-talk
├───devShells
│   ├───aarch64-darwin
│   │   └───default: development environment 'nix-shell'
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
└───packages
    ├───aarch64-darwin
    │   └───default: package 'srug-nix-0.1.0'
    └───x86_64-linux
        └───default: package 'srug-nix-0.1.0'
```

Every defined system is part of the output, the `nix` command just chooses the
right one. You can ever force it to use the wrong system:

```
❯ nix run .#packages.x86_64-linux.default
Hello, world!
❯ nix run .#packages.aarch64-darwin.default
error: a 'aarch64-darwin' with features {} is required to build '/nix/store/vlvsdb6l9zw6hrmpv384w1mzimbvb3fv-dummy.rs.drv', but I am a 'x86_64-linux' with features {benchmark, big-parallel, kvm, nixos-test}
```


---

Great, now we can use our flake on any supported system. However, this has a
downside, if we want to reuse our package definition, we'd have to wrap it in
another function. 

Luckily, we can pull in another input to clean this up a bit: [hercules-ci/flake-parts](https://github.com/hercules-ci/flake-parts).

----

```nix
{
  description = "A super basic Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    crane.url = "github:ipetkov/crane";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = {
    self,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-darwin"];
      perSystem = {
        self',
        inputs',
        pkgs,
        ...
      }: let
        crane = inputs.crane.mkLib pkgs;
        src = crane.cleanCargoSource ./.;

        commonArgs = {
          inherit src;
        };

        cargoArtifacts = crane.buildDepsOnly commonArgs;

        srugNix = crane.buildPackage (
          commonArgs // {inherit cargoArtifacts;}
        );
      in {
        packages.default = srugNix;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [cargo llvm];
        };
        checks = {
          inherit srugNix;

          clippy = crane.cargoClippy (
            commonArgs
            // {
              inherit cargoArtifacts;
              cargoClippyExtraArgs = "--all-targets -- --deny warnings";
            }
          );

          fmt = crane.cargoFmt {
            inherit src;
          };
        };
      };
    };
}
```

If you squint a little, you can see our old flake (`perSystem`) wrapped with
logic that generates it for each system (`flake-parts.lib.mkFlake`).

