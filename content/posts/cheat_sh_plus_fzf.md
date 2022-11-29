---
title: "Cheat Sh Plus Fzf"
date: 2022-11-28T17:45:32-08:00
tags: ["fzf", "cheat.sh", "zsh", "tmux"]

draft: true
---

If you've used a Unix system for any length of time you've probably read a `man`
page or two. Right after opening your first `man` page you might have googled
something along the lines of "How to search in a man page". `man` pages are
dense, detailed, documents.

On the other hand, [`cheat.sh`](https://cheat.sh/) provides a short, community curated
*cheat sheet* for many popular commands (and programming languages) filled with examples.

However, the defacto interface to `cheat.sh` is `curl` - not very user friendly.
This walks through my development process of creating a shell script that:
  -	Filters `cheat.sh` endpoints using `fzf`.
  -	Formats the `curl` request (both the url string and response data).
  - Create a key bind to call the script.


<!--more-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Inspiration](#inspiration)
- [Alternatives](#alternatives)
  - [`tldr`](#tldr)
  - [`cht.sh`](#chtsh)
- [Development](#development)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Inspiration
"ThePrimeagen" publish a video in Sept. 2021 with an identical concept.
Although his solution required manually updated local files to work and
spawns the results is a temporary `tmux` window.
Check out the [video][prime-video]!

# Alternatives
## `tldr`
[`tldr.sh`](https://tldr.sh/) is very similar to `cheat.sh`, with a larger
focus on examples and cli clients. However, `cheat.sh` has a larger library
and returns	the `tldr` information in addition to any `cheat.sh` specific
information.

I used this tool prior to building my own.

## `cht.sh`

`curl https://cht.sh/:cht.sh > .local/bin/cht.sh` downloads the official
cli tool. This solves the awkward curl command construction, but its still
missing a nice fuzzy finding interface.

# Development

<!-- Links -->
[prime-video]: https://www.youtube.com/watch?v=hJzqEAf2U4I
