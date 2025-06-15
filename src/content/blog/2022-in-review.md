---
title: "2022 in Review"
pubDate: "2022-12-31"

draft: false
---

2022 was a busy year, this is a concise review of almost everything
I did & learned.

![My ~~Mood Graph~~ GitHub Commit Graph for 2022](../../static/images/posts/2022-in-review/github-graph.png)

<!--more-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [January](#january)
  - [My First Dagger Commit](#my-first-dagger-commit)
  - [Set Up Gitea](#set-up-gitea)
- [February](#february)
  - [Ansible (For Local Host)](#ansible-for-local-host)
- [March](#march)
  - [Dagger-ified RoboShpee](#dagger-ified-roboshpee)
  - [Dagger-ified this blog.](#dagger-ified-this-blog)
  - [Breaking Dagger](#breaking-dagger)
  - [WireGuard Setup](#wireguard-setup)
- [April & May](#april--may)
  - [Java Design Patterns](#java-design-patterns)
- [June, July, & August](#june-july--august)
  - [FlightAware](#flightaware)
- [September](#september)
- [October](#october)
  - [Hyperland, Eww & Nasty Notifications](#hyperland-eww--nasty-notifications)
  - [Ansible (For the Homelab)](#ansible-for-the-homelab)
  - [Blog Posts](#blog-posts)
    - [GPG Keys](#gpg-keys)
    - [Dagger (CUE SDK) and GitHub Actions](#dagger-cue-sdk-and-github-actions)
- [November](#november)
  - [Second Keyboard](#second-keyboard)
  - [Dagger Python SDK](#dagger-python-sdk)
- [December](#december)
  - [Raincloud](#raincloud)
  - [Rattlesume](#rattlesume)
  - [Cheat.sh](#cheatsh)
- [2023 & Beyond](#2023--beyond)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# January

## My First Dagger Commit

[dagger/dagger #1355](https://github.com/dagger/dagger/pull/1355)

This was a simple one-line commit that updated the documentation around
shell auto-completion.

## Set Up Gitea

[Getting Going With Gitea](/posts/getting-gitea/)

In late January I set up a Gitea server to host my school projects
without overcrowding my GitHub profile with private repositories.

I learned a lot about networking during this project. I got to configure
both HTTPS and SSH (on a nonstandard port), and routing them from the public
internet through the reverse proxy, VM, and finally onto the Docker container.

# February

## Ansible (For Local Host)

[Ansible For Local Host](/posts/ansible_for_localhost/)

This is a simple collection of scripts that configures a fresh
Arch Linux install. It saved my bacon when I had to do a quick
re-install on my laptop.

# March


## Dagger-ified RoboShpee

[KGB33/RoboShpee PR #8](https://github.com/KGB33/RoboShpee/pull/8)

I converted the Dockerfile that was being used to build `RoboShpee`
to dagger (what is now the CUE SDK). Later that day I reverted the PR
because multi-platform builds were not yet supported -- the bot runs
on a Raspberry Pi (`arm`) & GitHub Actions runs on `amd`.

## Dagger-ified this blog.

[KGB33/blog.kgb33.dev PR #2](https://github.com/KGB33/blog.kgb33.dev/pull/2)
[Daggerify the Blog](https://blog.kgb33.dev/posts/daggerify-the-blog/)

Not discouraged by the RoboShpee failure, I Dagger-ified the blog.
The containerization pipeline is fairly simple, but the theme I use
requires Hugo extended, which needs to be built from source. Which required
`Go 1.18`, at the time the dagger CUE SDK provided `1.16` as the default;
so I submitted a PR...

## Breaking Dagger

[dagger/dagger PR #1944](https://github.com/dagger/dagger/pull/1944)

This was a fairly simple PR, bump the Go version, add an underscore,
fix a typo so the tests actually ran. It passed all the tests and
was merged without issue.

Then the next day [dagger/dagger Issue #1965](https://github.com/dagger/dagger/issues/1965)
was submitted. TLDR: Go 1.18 added VCS info in compiled binaries by default, but dagger was
a. not sending the `.git` directory by default, and b. the Alpine Linux base container did not have
the `git` binary.

## WireGuard Setup

[Point-To-Site WireGuard](/posts/wireguard/)

I configured a spit tunnel VPN using WireGuard, OPNsense, and systemd-networkd.


# April & May

## Java Design Patterns

[CSCD 212 Final Project](https://github.com/KGB33/EWU-CSCD212-Final-Group-Project)

This group project was particularly challenging not because of the content, but because
of the group members. A range of operating systems and editors were used throughout the
group, and it needed to run first try on the Grader's system too. Using Gradle and GitHub
actions ensured that all group members submitted code with a uniform style and passing tests.


# June, July, & August

## FlightAware

Over the summer I was a Systems Intern at FlightAware working as part
of the Operations team.

I used my existing Python skills to build `KNIT`, a two part program used to collect
fairly constant device information. Then, to deploy KNIT, I leveraged the existing tools that my
co-workers had implemented.

![KNIT Diagram](https://flightaware.engineering/content/images/2022/08/image-1.png)

The device agent was deployed to every bare-metal Linux machine using Salt Stack. It then
runs once a day and sends a JSON payload to a RabbitMQ instance in Kubernetes.

The RabbitMQ instance is configured using Flux, Kustomize, and [the RabbitMQ
Kubernetes
Operator](https://www.rabbitmq.com/kubernetes/operator/operator-overview.html#cluster-operator).

Lastly, the second part pulls data from the RabbitMQ instance and pushes it into Netbox.
KNIT also implements a simple retry backoff loop if Netbox is unavailable.
This part is also deployed using Flux, Kustomize, and Kubernetes.

Both parts are containerized using Nix in GitHub actions, with secrets managed using Mozilla SOPS.

![KNIT Retry Diagram](../../static/images/posts/2022-in-review/KNIT-retry-diagrams.jpg "Two possible retry mechanisums, The one on the right was chosen.")

# September

I built a Keyboard & swapped to the Dvorak layout!

Swapping from a staggered to otholinear was enough of a shock for my
muscle memory swapping layouts didn't hurt much more.

I also swapped to home row mods, "precondition" has an excellent write-up
on them](https://precondition.github.io/home-row-mods) (I use "GACS/◆⎇⎈⇧").

![Solfe v2 RGB](../../static/images/posts/2022-in-review/solfev2.jpg)

Also, (technically in October) I configured `Kmonad` to change my laptop layout
to match my desktop Keyboard.

# October

## Hyperland, Eww & Nasty Notifications

In October, I changed my window manager from Sway to Hyperland,
and with it, I redid my status bar using [Elkowars Wacky Widgets](https://github.com/elkowar/eww)

[Nasty Notifications](https://github.com/KGB33/nasty) is my solution to some missing
portions of Eww. It's a rust CLI that provides a Freedesktop Notification server interface
as well as Hyperland workspace information.

## Ansible (For the Homelab)

[KGB33/ansible](https://github.com/KGB33/ansible)

Using Salt at FlightAware made me keenly aware of my need for a similar tool
in my homelab. After considering Chef, Puppet, Salt & Ansible I ended up going
with Ansible due to three main reasons:
  - Excellent Documentation
  - Written in Python
  - Primarily a push model


I started In October with a few simple playbooks, but improvements & additions
continued throughout the remainder of the year.

## Blog Posts

### [GPG Keys](/posts/gpg_keys/)

A quick walk through of creating GPG keys and configuring Git and GitHub.

### [Dagger (CUE SDK) and GitHub Actions](/posts/daggerify-part-2/)

This is a continuation from "Daggerifing the Blog- Part 1" from back in
March. It quickly goes over using GitHub actions to build whenever changes
are made to `main`.

# November

## Second Keyboard

Not content with just settling for Kmonad on my laptop, I
built a wireless Ferris Sweep to use as a travel Keyboard.
Although, it quickly became my favorite, mainly due to its
small form factor.

My [Key map Firmware](https://github.com/KGB33/zmk-config) repo
has an excellent key map diagram.

## Dagger Python SDK

I was lucky enough to gain access to the Dagger Python SDK early access.
I took full advantage of this by re-daggerifing RoboShpee - after all, it's a python program
and dagger now has multi-platform support.

KGB33/RoboShpee PR [#11](https://github.com/KGB33/RoboShpee/pull/11) added support for the beta
and PR [#12](https://github.com/KGB33/RoboShpee/pull/12) added support for the full release &
added GitHub Actions.


I also contributed back to the Python SDK by improving some error messages
[PR #3825](https://github.com/dagger/dagger/pull/3825) and the associated tests
in [PR #3880](https://github.com/dagger/dagger/pull/3880).

# December

December was a weird month, I spent half of it learning about Packer,
Terraform, and Cloud-init; and the other half applying to jobs.
The two following projects are direct results of this.

## Raincloud

[KGB33/raincloud](https://github.com/KGB33/raincloud)

A rust TFTP (Trivial File Transfer Protocol) server that serves a git repository.
Primarily designed to serve `user-data` Cloud-init files.

## Rattlesume

[KGB33/rattlesume](https://github.com/KGB33/rattlesume)

A python CLI that combines markdown snippets into a complete document as defined
by YAML files.

## [Cheat.sh](/posts/cheat_sh_plus_fzf/)

I created a zsh plugin that fuzzy searches over [cheat.sh](https://cheat.sh)
entries & wrote a blog post describing my process.

# 2023 & Beyond

I have a few goals for 2023:
  - Set up a local DNS server
  - Ansiblilze a Kubernetes Cluster.
  - Deploy to said cluster using GitOps (Flux or ArgoCD)
  - Experiment with:
    - VyOS
    - Ceph
  - Keep an engineering journal - it should help make writing next year's review a lot easier.
