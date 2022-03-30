---
title: "Daggerify the Blog - Part 1: Build"
date: 2022-03-30T09:23:50-07:00
tags: ["dagger", "docker"]

draft: true
---

The original deployment strategy ([detailed here][blog-deployment]) for this blog was
manual and error prone. The ideal goal is to use [dagger][dagger] to build out
the whole CI/CD system, from building the image to deploying on a local Kubernetes cluster.

Part 1 covers building the docker image an pushing it to the Github container registry.

<!--more-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Building](#building)
  - [Hugo Extended](#hugo-extended)
    - [Base Go 1.18 image](#base-go-118-image)
    - [Pull Hugo Source code](#pull-hugo-source-code)
    - [Build Hugo](#build-hugo)
  - [NPM](#npm)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Building

The container image can be broken into a few parts.

1. The Hugo extended binary.
1. The Node and NPM binaries.
1. The theme and its dependencies.
1. The actual content of the blog.

## Hugo Extended

Dagger provides a way to build a go binary using the Dagger Universe [Go package][dagger-uni-go].

Each of the following is an action defined with a [dagger plan][dagger-plan].

### Base Go 1.18 image

First a base image with Go 1.18 need to be created. It is defined as the
[disjunction][cue-disjunction] between the `go.#Image` struct, and the
`{version: "1.18"}` struct. The output of this step, defined by `go.#Image`,
can be used by other actions; kinda like multi-stage docker builds.

```cue-lang
package main

import (
        "dagger.io/dagger"
        "universe.dagger.io/go"
)

dagger.#Plan & {
        actions: {
                _baseGo: go.#Image & {
                        version: "1.18"
                }
        }
}
```

> Note: The underscore in `_baseGo` marks it as a hidden field.

### Pull Hugo Source code

The Hugo source can be pulled in using the Dagger [git package][dagger-uni-git].

```cue-lang
package main

import (
        "dagger.io/dagger"
        "universe.dagger.io/git"
)

dagger.#Plan & {
        actions: {
                _hugoSource: git.#Pull & {
                        remote: "https://github.com/gohugoio/hugo.git"
                        ref:    "v0.96.0"
                }
        }
}
```

### Build Hugo

This action utilizes the output of the previous two actions to build the hugo
binary. Notice how `_hugoSource.output` and `_baseGo.output` are passed to
the `go.#Build` struct.

```cue-lang
package main

import (
        "dagger.io/dagger"
        "universe.dagger.io/go"
        "universe.dagger.io/git"
)

dagger.#Plan & {
        actions: {
                _baseGo: go.#Image & {
                        version: "1.18"
                }
                _hugoSource: git.#Pull & {
                        remote: "https://github.com/gohugoio/hugo.git"
                        ref:    "v0.96.0"
                }
                _hugoBin: go.#Build & {
                        source: _hugoSource.output
                        container: go.#Container & {input: _baseGo.output}
                }
        }
}
```

## NPM

<!-- links -->

[blog-deployment]: https://blog.kgb33.dev/posts/getting_started_with_hugo/#production
[dagger]: https://dagger.io/
[dagger-plan]: https://docs.dagger.io/1202/plan
[dagger-uni-go]: https://github.com/dagger/dagger/tree/main/pkg/universe.dagger.io/go
[dagger-uni-git]: https://github.com/dagger/dagger/tree/main/pkg/universe.dagger.io/git
[cue-disjunction]: https://cuelang.org/docs/tutorials/tour/types/disjunctions/
