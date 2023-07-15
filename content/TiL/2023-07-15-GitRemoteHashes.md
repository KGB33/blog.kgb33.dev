---
title: "TiL..About `git` remotes"
date: 2023-07-15T13:04:44-07:00
tags: ["TiL", "nixos"]

draft: false
---

I'm trying out daily driving NixOS and one of the problems I have is knowing
when updates are available. On NixOS all the packages are defined in a
**giant** git repository -
[github:nixos/nixpkgs](https://github.com/nixos/nixpkgs) - and updates are
commits to the various branches (called channels) of this repo. Then, my system
is locked to a particular commit hash for whichever channel I'm comfortable
running. Thus, to find out if there are updates available I just have to check
if the most recent hash is in the lock file.

<!--more--> 
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# `flake.lock`

The (very truncated) lock file for my system is below. The
`nodes.nixpkgs.locked.rev` value is the git commit on the that I'm using. It is
also the latest commit on the `nodes.nixpkgs.original.ref` branch. At least it
is if there are not any updates.

```json
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "lastModified": 1689282004,
        "narHash": "sha256-VNhuyb10c9SV+3hZOlxwJwzEGytZ31gN9w4nPCnNvdI=",
        "owner": "nixos",
        "repo": "nixpkgs",
        "rev": "e74e68449c385db82de3170288a28cd0f608544f",
        "type": "github"
      },
      "original": {
        "owner": "nixos",
        "ref": "nixos-unstable",
        "repo": "nixpkgs",
        "type": "github"
      }
    }
  }
}
```

# *git*ting the Remote Hash

There are three methods to get the latest commit on a branch. The worst way is
to clone the whole repo, checkout the branch and run `git show-ref HEAD | awk
'{print $1}'`. Three whole commands, that's two too many. More importantly,
downloading the nixpkgs repo takes a lot of bandwidth. 

An alternative is to use `git ls-remote`. 

```
$ git ls-remote https://github.com/NixOS/nixpkgs.git nixos-unstable | awk '{print $1}'
e74e68449c385db82de3170288a28cd0f608544f
```

This takes longer than I'd like though...

```
$ time git ls-remote https://github.com/NixOS/nixpkgs.git nixos-unstable | awk '{print $1}'
e74e68449c385db82de3170288a28cd0f608544f
git ls-remote https://github.com/NixOS/nixpkgs.git nixos-unstable  0.26s user 0.32s system 37% cpu 1.561 total
awk '{print $1}'  0.00s user 0.00s system 0% cpu 1.560 total
```

Lastly, Github has an API I can use. 

```
$ curl -s https://api.github.com/repos/nixos/nixpkgs/branches/nixos-unstable | jq '.commit.sha'
e74e68449c385db82de3170288a28cd0f608544f
```

Luckily this is significantly faster.

```
$ time curl -s https://api.github.com/repos/nixos/nixpkgs/branches/nixos-unstable | jq '.commit.sha'
"dfdbcc428f365071f0ca3888f6ec8c25c3792885"
curl -s https://api.github.com/repos/nixos/nixpkgs/branches/nixos-unstable  0.06s user 0.01s system 27% cpu 0.239 total
jq '.commit.sha'  0.02s user 0.00s system 8% cpu 0.238 total
```

# Updates?

Now that we have the remote hash, we just need to see if it is in our `/etc/nixos/flake.lock`, and ripgrep is the perfect tool.

```
$ rg -c $(curl -s https://api.github.com/repos/nixos/nixpkgs/branches/nixos-unstable | jq '.commit.sha') /etc/nixos/flake.lock
1
```

In the above command the most recent hash is substituted for the `$(...)` and
then `rg` counts the number of occurrences in the provided path.

Then I can take this command and pass it to my `eww` widgets to display an icon
when updates are available. 
