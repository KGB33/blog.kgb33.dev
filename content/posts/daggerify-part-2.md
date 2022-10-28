---
title: "Dagger in Github Actions"
date: 2022-10-09T15:26:22-07:00
draft: False
---

It's been a while since part one and I've learned so much about automation and GitOps.
The overall goal for this project is still the same, an automated CI/CD system, but some
of the technologies have changed. This particular post is all about integrating Dagger and Github Actions.

<!--more-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Running The Action](#running-the-action)
- [Dagger Action](#dagger-action)
  - [Buildkit Caching](#buildkit-caching)
- [Permissions](#permissions)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Running The Action

I want changes to go live as soon as possible. To accomplish this the action will run
whenever something is pushed to the `main` branch.

```yaml
concurrency: release

on:
  workflow_dispatch:
  push:
    branches:
      - 'main'
```

> Note:`concurrency: release`: This prevents race conditions and ensures that the packages
> are pushed to GHCR in the correct order.


# Dagger Action

The entire Github Action pipeline consists of two steps.
  1. Checkout the code.
  1. Run Dagger.

Installing Dagger is handled by the [dagger-for-github](https://github.com/dagger/dagger-for-github/)
action.

```yaml
jobs:
  publish:
    name: "Build & Push to GHCR"
    runs-on: ubuntu-latest
    steps:
      - name: "Check out"
        uses: actions/checkout@v2
        with:
          fetch-depth: 0
      - name: "Callout to dagger"
        uses: dagger/dagger-for-github@v3
        env:
          GHCR_PAT: ${{ secrets.GITHUB_TOKEN }}
        with:
          # Use buildkit's gha cache support
          # Watch https://github.com/dagger/dagger-for-github/issues/39
          # for cache support being built-into the dagger-action
          cmds: |
            project init
            project update
            do --cache-from type=gha --cache-to type=gha publish
```

> Note: The `GITHUB_TOKEN` secret is passed to Dagger as the `GHCR_PAT` environment variable
> because the dagger plan expects the Github Token to be called `GHCR_PAT`.


## Buildkit Caching

Caching is provided "for free" by buildkit using their special `gha` type cache.
Eventually this will be configurable using the `with:` section on the `dagger-for-github`
action. Keep an eye on [Issue #39](https://github.com/dagger/dagger-for-github/issues/39).

# Permissions
This workflow requires two permissions to be granted to `${{ secrets.GITHUB_TOKEN }}`.

```yaml
permissions:
  packages: write
  actions: write
```
The first seems self explanatory, but the action also needs to be given permission from the package
settings. Allowing access to `actions` enables caching. Both of these are included in the (rather
permissive) default permissions. However, defining any permissions denies the remaining.
