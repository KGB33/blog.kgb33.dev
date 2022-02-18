---
title: "Neovim for Java"
date: 2022-01-26T07:19:48-08:00
tags: ["neovim", "java", "gradle", "jdtls", "dap"]

draft: true
---

<!--more-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Prerequisites](#prerequisites)
- [Setting up `mfussenegger/nvim-jdtls`](#setting-up-mfusseneggernvim-jdtls)
  - [Eclipse jdtls Installation](#eclipse-jdtls-installation)
  - [Configuration](#configuration)
  - [Issues](#issues)
- [Gradle](#gradle)
- [Setting up `mfussenegger/nvim-dap`](#setting-up-mfusseneggernvim-dap)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Prerequisites

# Setting up `mfussenegger/nvim-jdtls`
## Eclipse jdtls Installation
  - Manually download & Install
  - Pacman hook to copy to /home/username
  - Lua script

## Configuration
  - path to jdtls
  - data dir

## Issues
  - jdtls only attaches to the first instance of neovim.
  I.e. With an open java file, `:vsp newfile.java` will have a lsp present, `nvim newfile.java` will not.
  - Organize code imports fails with `jdt.ls: -32601: No delegateCommandHandler for java.action.organizeImports`

# Gradle
  - Calling gradle tasks from nvim (telescope plugin??)
  - Sending compile/Checkstyle errors to the quickfix list.

# Setting up `mfussenegger/nvim-dap`

> Note: Both `nvim-dap` and `nvim-jdtls` are maintained by mfussenegger,
> however `nvim-dap` works with multiple languages (See [here][dap-adapters] for a list).


<!-- links -->
[dap-adapters]: https://microsoft.github.io/debug-adapter-protocol/implementors/adapters/
