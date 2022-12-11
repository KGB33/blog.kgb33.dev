---
title: "Cheat.sh + fzf"
date: 2022-12-10T23:00:00-08:00
tags: ["fzf", "cheat.sh", "zsh", "tmux"]

draft: false
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
  - [Url Format](#url-format)
    - [`cheat.sh/:list`](#cheatshlist)
  - [Stringing it all together.](#stringing-it-all-together)
    - [Selecting the topic](#selecting-the-topic)
    - [Paging the Cheat Sheet](#paging-the-cheat-sheet)
    - [Combining the Two](#combining-the-two)
    - [Complete* Script](#complete-script)
  - [Integrating `ZLE`](#integrating-zle)
    - [The Widget](#the-widget)
    - [ZLE Initiation](#zle-initiation)
  - [An Important Wrapper](#an-important-wrapper)
- [Summary](#summary)
- [Gallery](#gallery)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Inspiration

"ThePrimeagen" published a video in Sept. 2021 with an identical concept.
Although his solution required manually updated local files to work and
spawns the results is a temporary `tmux` window.
Check out the [video][prime-video]!


Additionally, the `fzf-git` [source code][fzf-git-source] was
extremely helpful to use as a base.

# Alternatives

## `tldr`

[`tldr.sh`](https://tldr.sh/) is very similar to `cheat.sh`, with a larger
focus on examples and cli clients. However, `cheat.sh` has a larger library
and returns	the `tldr` information in addition to any `cheat.sh` specific
information.

I used this tool prior to building my own.

## `cht.sh`

`curl https://cht.sh/:cht.sh > .local/bin/cht.sh` downloads the official
cli tool. This solves the awkward curl command construction, but it's still
missing a nice fuzzy finding interface.

# Development

## Url Format

The cheat.sh urls are formatted as follows:
```
[https://]cheat.sh/{topic}?[options]
```
  - The https prefix is optional (thanks curl!)
  - options include stuff like style & removing escape characters.
  - `topic` is the meat and potato of the url.

`topic` can be formatted a number of different ways.
  - The `:` prefix denotes a special 'meta' url, e.x. `cheat.sh/:help`
  - Sub-topics can be accessed via `{topic}-{subtopic}`, e.x `cheat.sh/git-clone
  - The `~` prefix denotes a search `cheat.sh/git-clone~depth`

### `cheat.sh/:list`

`cheat.sh/:list` is what makes this work. It returns a list of all
the valid topics, ready to be substituted into the url.

## Stringing it all together.

The script consists of two main parts, selecting the topic using `fzf`,
and displaying the cheat-sheet for that topic.

### Selecting the topic

To select the topic we first get the special `:list` endpoint,
then pipe that into `fzf-tmux`.

> Note: `fzf-tmux` is a special wrapper around `fzf` that will open
> the selection menu in a tmux pane when called in a `tmux` session,
> otherwise, it acts the same as normal `fzf`.

```console
curl --silent "cheat.sh/:list" | fzf-tmux
```
`fzf` then returns the single entry, which conveniently
can be tacked on to the end `cheat.sh/` of the URL.

This can be extracted into the following function:

```shell
STYLE='rrt'

__fzf_cheat_selector() {
	curl --silent "cheat.sh/:list" | fzf-tmux \
	# The followning lines are optional
	-p 70%,60% \
	--layout=reverse --multi \
	--preview "curl --silent cheat.sh/{}\?style=$STYLE" \
	--bind "?:toggle-preview" \
	--preview-window hidden,60% \
}
```

> Note: If you do choose to have a preview window
> make sure it defaults to closed to prevent excess
> network calls.

### Paging the Cheat Sheet

Now that we have our topic we can easily curl the cheat sheet,
making it look good is another story. Cheat.sh returns what I'm
going to call "terminal friendly" markdown. It (by default)
has super basic syntax highlighting, but we can improve it by passing
the result to a pager.

I personally use [`bat`][bat-url] as my pager of choice,
but `less`, [`glow`][glow-url], or [`rich-cli`][rich-cli-url] could all be used.

It's fairly simple to pipe the cheat-sheet to these commands,
but whichever command you choose needs to be told that it
should render markdown.

```shell
fzf_cheat_sh() {
	curl --silent "cheat.sh/$TOPIC" \
	| bat --style=plain -l markdown
}
```

### Combining the Two

Easy, Now just to wire them together. Replace, `$TOPIC` with
the following `${1:=$(__fzf_cheat_selector)}`.

The `${1:=$val}` syntax means use the first variable, or if that
doesn't exist, use `$val` as a default.


### Complete* Script

```shell
__fzf_cheat_selector() {
        curl --silent "cheat.sh/:list" \
        | fzf-tmux \
            -p 70%,60% \
            --layout=reverse --multi \
            --preview \
            "curl --silent cheat.sh/{}\?style=$STYLE" \
            --bind "?:toggle-preview" \
            --preview-window hidden,60% \
}

fzf_cheat_sh() {
    curl --silent "cheat.sh/${1:=$(__fzf_cheat_selector)}?style=$STYLE" \
    | bat --style=plain
}

```

This script is ready to go as-is. Just source in your `.zshrc` and
run `fzf_cheat_sh`

## Integrating `ZLE`

If you use `zsh` probably already used [Zsh Line Editor][zle-docs] (zle),
possibly without even knowing about it. For example "vim" mode is built on top
of it.

We're going to create a key bind that puts our `fzf_cheat_sh` command on the
buffer line then run it. This has the added benefit of adding the command
(with the topic query) to the history.

There are three parts, defining the "widget", adding it to `zle`, and creating the
key bind.

### The Widget

```shell
_fzf_cheat_sh_widget() {
    zle push-input;
    BUFFER="fzf_cheat_sh $(__fzf_cheat_selector)";
    zle accept-line;
}
```

This function does three things:
  - Removes all content from the line
  - Sets the buffer to the fzf_cheat_sh command (and runs the fzf selector)
  - Runs the command

### ZLE Initiation

ZLE still needs to be told that the above widegt exists.

```shell
__fzf_cheat_init() {
  eval "zle -N _fzf_cheat_sh_widget"
  eval "bindkey '^_' _fzf_cheat_sh_widget"
}
__fzf_cheat_init
```

Here, `zle` is told about the widget. Then the key map is defined as (visually)
`Ctrl+?`.


## An Important Wrapper

The whole script is wrapped in an `if` statement so it
will only be loaded in an interactive terminal.

```shell
if [[ $- =~ i ]]; then

# The Whole Script Goes in Here

fi
```
# Summary

When an new *interactive* shell is started the commands and
zle plugin is loaded. Then the program can be started using
the key bind or by typing the command out manually.
Once the key bind is pressed zle remove the current content
from the buffer; prompts using the `fzf` selector; then
pushes the command & topic to the buffer; then lastly runs the command.

This simple & easy workflow is perfect for double-checking arguments,
flags, and common use cases without breaking your train of thought.

# Gallery

![In a multi-pane tmux session](/images/posts/cheatsh/tmux_multi_pane.png)
![With a preview window](/images/posts/cheatsh/preview_window.png)
![Output for `git-commit`](/images/posts/cheatsh/git_commit_output.png)


<!-- Links -->
[prime-video]: https://www.youtube.com/watch?v=hJzqEAf2U4I
[fzf-git-source]: https://github.com/junegunn/fzf-git.sh

[bat-url]: https://github.com/sharkdp/bat
[glow-url]: https://github.com/charmbracelet/glow
[rich-cli-url]: https://github.com/textualize/rich-cli
[zle-docs]: https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html
