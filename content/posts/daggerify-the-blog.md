---
title: "Daggerify the Blog - Part 1: Build"
date: 2022-03-30T09:23:50-07:00
tags: ["dagger", "docker"]

draft: false
---

The original deployment strategy ([detailed here][blog-deployment]) for this blog was
manual and error prone. The ideal goal is to use [dagger][dagger] to build out
the whole CI/CD system; from building the image to deploying on a local Kubernetes cluster.

Part 1 covers building the docker image and pushing it to the Github container registry.

<!--more-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Building](#building)
  - [Hugo Extended](#hugo-extended)
    - [Base Go 1.18 image](#base-go-118-image)
    - [Pull Hugo Source code](#pull-hugo-source-code)
    - [Build Hugo](#build-hugo)
  - [Base dependencies](#base-dependencies)
  - [Putting it all Together](#putting-it-all-together)
    - [Copy Hugo Binary and Theme Files](#copy-hugo-binary-and-theme-files)
    - [Copy `sum` and `lock` Files](#copy-sum-and-lock-files)
    - [Download and Install Dependencies](#download-and-install-dependencies)
    - [Copy Blog Content](#copy-blog-content)
    - [Set Configuration](#set-configuration)
  - [Local convenience Actions](#local-convenience-actions)
  - [Complete Actions](#complete-actions)

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
can be used by other actions; similar to multi-stage docker builds.

```cue
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

```cue
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

```cue
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

## Base dependencies

Create a new image using `universe.dagger.io/apline.#Build` with the packages that we need.

> Note: We could specify the versions needed (replace the underscore)
> but alpine already pins package versions to the distribution version.
> See [Issue #1532][dagger-gh-issue-1532] for more info.

```cue
dagger.#Plan & {
        actions: {
                _base: alpine.#Build & {
                        packages: {
                                "npm": _
                                "go":  _
                                "git": _
                        }
                }
        }
}
```

## Putting it all Together

This last action is the biggest. It is a series of steps in `docker.#Build`
where each step can be thought of a line in a Dockerfile. I am going to explain
each step in order, then display the completed action at the end.

### Copy Hugo Binary and Theme Files

Starting with the image generated from the `_base` step,
copy the hugo binary to `/bin/hugo`, then copy the theme files
to `blog/themes/gruvbox/`.

```cue
dagger.#Plan & {
        actions: {
                build: docker.#Build & {
                        steps: [
                                _base,
                                docker.#Copy & {contents: _hugoBin.output, dest: "/bin/"},
                                docker.#Copy & {contents: _theme.output, dest: "/blog/themes/gruvbox/"},

                                ...
								]
						}
				}
}
```

### Copy `sum` and `lock` Files

Next, copy over various package definition files.
These are copied over before the rest of the content
to utilize the builtin caching.

```cue
dagger.#Plan & {
	client: {
		filesystem: "./": read: {
			contents: dagger.#FS
			exclude: ["node_modules", "public", "build.cue", "cue.mod", "themes", ".envrc"]
		}
	}
    actions: {
		build: docker.#Build & {
            steps: [
				...
				docker.#Copy & {
                            contents: client.filesystem."./".read.contents
                            include: ["go.mod", "go.sum", "package.json", "package-lock.json", "package.hugo.json", "config.toml"]
                            dest: "/blog/"
                },
				...
			]
		}
	}
}
```

### Download and Install Dependencies

A fairly self explanatory set of steps.

```cue
dagger.#Plan & {
    actions: {
		build: docker.#Build & {
            steps: [
				...
                docker.#Run & {
                        workdir: "/blog/"
                        command: {name: "hugo", args: ["mod", "get"]}
                },
                docker.#Run & {
                        workdir: "/blog/"
                        command: {name: "hugo", args: ["mod", "npm", "pack"]}
                },
                docker.#Run & {
                        workdir: "/blog/"
                        command: {name: "npm", args: ["install"]}
                },
				...
			]
		}
	}
}
```

### Copy Blog Content

Once again a simple step. Just copying frequently changed content files
into the image.

```cue
dagger.#Plan & {
    actions: {
		build: docker.#Build & {
            steps: [
				...
				docker.#Copy & {
                    contents: client.filesystem."./".read.contents
                    dest:     "/blog/"
                },
				...
			]
		}
	}
}
```

### Set Configuration

This step sets a view values defined [here][dagger-img-conf]. `workdir` is self
explanatory, it sets the working directory for the `cmd` option. `cmd` is the
command that runs by default. In other words, when `docker run $IMG_NAME` is
run it starts the container and calls the command defined by `cmd`.

Lastly `label` is used to connect the entry on the Github Container registry to
the github repository where the source code is stored.

```cue
dagger.#Plan & {
    actions: {
		build: docker.#Build & {
            steps: [
				...
                docker.#Set & {config: {
                    workdir: "/blog/"
                    cmd: ["/bin/hugo", "server", "--bind=0.0.0.0"]
                    label: "org.opencontainers.image.source": "https://github.com/kgb33/blog.kgb33.dev"
                }},
				...
			]
		}
	}
}
```

## Local convenience Actions

`dagger do local load` loads the image into the local docker registry.

`dagger do local run` automatically runs the hugo server. Although this will
cause dagger to hang because the action never completes.

```cue
dagger.#Plan & {
    actions: {
		local: {
            load: cli.#Load & {
                    image: build.output
                    tag:   "blog.kgb33.dev:latest"
                    host:  client.network."unix:///var/run/docker.sock".connect
            }
            // Unsure how to detach from container Currently dagger 'hangs'
            // while running the hugo server. Cancel via <Ctrl-C>
            run: cli.#Run & {
                    cli.#RunSocket & {
                            host: client.network."unix:///var/run/docker.sock".connect
                    }
                    input: build.output
            }
        }
	}
}
```

## Complete Actions

```cue
package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"universe.dagger.io/docker/cli"
	"universe.dagger.io/alpine"
	"universe.dagger.io/go"
	"universe.dagger.io/git"
)

dagger.#Plan & {
	client: {
		filesystem: "./": read: {
			contents: dagger.#FS
			exclude: ["node_modules", "public", "build.cue", "cue.mod", "themes", ".envrc"]
		}
		env: GHCR_PAT: dagger.#Secret
		network: "unix:///var/run/docker.sock": connect: dagger.#Socket
	}

	actions: {
		_baseGo: go.#Image & {
			version: "1.18"
			packages: {
				"gcc": _
				"g++": _
			}
		}
		_hugoSource: git.#Pull & {
			remote: "https://github.com/gohugoio/hugo.git"
			ref:    "v0.96.0"
		}
		_hugoBin: go.#Build & {
			source:    _hugoSource.output
			container: go.#Container & {input: _baseGo.output}
			tags:      "extended"
			env: "CGO_ENABLED": "1"
		}
		_base: alpine.#Build & {
			packages: {
				"npm": _
				"go":  _
				"git": _
			}
		}
		_theme: git.#Pull & {
			remote: "https://github.com/schnerring/hugo-theme-gruvbox.git"
			ref:    "main"
		}
		build: docker.#Build & {
			steps: [
				_base,
				docker.#Copy & {contents: _hugoBin.output, dest: "/bin/"},

				docker.#Copy & {contents: _theme.output, dest: "/blog/themes/gruvbox/"},
				docker.#Copy & {
					contents: client.filesystem."./".read.contents
					include: ["go.mod", "go.sum", "package.json", "package-lock.json", "package.hugo.json", "config.toml"]
					dest: "/blog/"
				},
				docker.#Run & {
					workdir: "/blog/"
					command: {name: "hugo", args: ["mod", "get"]}
				},
				docker.#Run & {
					workdir: "/blog/"
					command: {name: "hugo", args: ["mod", "npm", "pack"]}
				},
				docker.#Run & {
					workdir: "/blog/"
					command: {name: "npm", args: ["install"]}
				},
				docker.#Copy & {
					contents: client.filesystem."./".read.contents
					dest:     "/blog/"
				},
				docker.#Set & {config: {
					workdir: "/blog/"
					cmd: ["/bin/hugo", "server", "--bind=0.0.0.0"]
					label: "org.opencontainers.image.source": "https://github.com/kgb33/blog.kgb33.dev"
				}},
			]
		}
		publish: docker.#Push & {
			dest:  "ghcr.io/kgb33/blog.kgb33.dev"
			image: build.output
			auth: {username: "kgb33", secret: client.env.GHCR_PAT}
		}
		local: {
			load: cli.#Load & {
				image: build.output
				tag:   "blog.kgb33.dev:latest"
				host:  client.network."unix:///var/run/docker.sock".connect
			}
			// Unsure how to detach from container Currently dagger 'hangs'
			// while running the hugo server. Cancel via <Ctrl-C>
			run: cli.#Run & {
				cli.#RunSocket & {
					host: client.network."unix:///var/run/docker.sock".connect
				}
				input: build.output
			}
		}
	}
}
```

<!-- links -->

[blog-deployment]: https://blog.kgb33.dev/posts/getting_started_with_hugo/#production
[dagger]: https://dagger.io/
[dagger-img-conf]: https://github.com/dagger/dagger/blob/7dbe4e9aa5da61d1ea2f5b12005812ff617a7ff5/pkg/dagger.io/dagger/image.cue#L12
[dagger-plan]: https://docs.dagger.io/1202/plan
[dagger-uni-go]: https://github.com/dagger/dagger/tree/v0.2.36/pkg/universe.dagger.io/go
[dagger-uni-git]: https://github.com/dagger/dagger/tree/v0.2.36/pkg/universe.dagger.io/git
[dagger-gh-issue-1532]: https://github.com/dagger/dagger/issues/1532
[cue-disjunction]: https://cuelang.org/docs/tutorials/tour/types/disjunctions/
