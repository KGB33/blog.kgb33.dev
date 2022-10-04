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
		_hugoSource: git.#Pull & {
			remote: "https://github.com/gohugoio/hugo.git"
			ref:    "v0.104.3"
		}
		_hugoBin: go.#Build & {
			source:    _hugoSource.output
		//	container: go.#Container & {input: _baseGo.output}
			tags:      "extended"
			env: "CGO_ENABLED": "1"
		}
		_base: alpine.#Build & {
			version: "3.16"
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
