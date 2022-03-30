package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"universe.dagger.io/alpine"
	"universe.dagger.io/go"
	"universe.dagger.io/git"
)

dagger.#Plan & {
	client: {
		filesystem: "./": read: {
			contents: dagger.#FS
			exclude: ["node_modules", "public", "build.cue", "cue.mod", "themes"]
		}
		env: GHCR_PAT: dagger.#Secret
	}

	actions: {
		_baseGo: go.#Image & {
			version: "1.18"
			packages: {
				"gcc":_
				"g++":_
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
					dest:     "/blog/"
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
				docker.#Set & {config: {
					workdir: "/blog/"
					cmd: ["/bin/hugo", "server", "--bind=0.0.0.0"]
				}},
			]
		}
	}
}
