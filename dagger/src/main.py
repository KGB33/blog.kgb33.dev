import os

import dagger
from dagger.mod import function

ENTRY_POINT = ["/bin/hugo", "server", "--bind=0.0.0.0"]


@function
def prod(dir: dagger.Directory) -> dagger.Container:
    return build(dir).with_entrypoint(ENTRY_POINT).with_default_args()


@function
async def run(dir: dagger.Directory) -> dagger.Service:
    """
    Example: `dagger up run --dir ...`
    """
    return build(dir).with_exec(ENTRY_POINT).as_service()


@function
async def publish(dir: dagger.Directory, token: dagger.Secret) -> str:
    return await (
        prod(dir)
        .with_registry_auth("ghcr.io", "KGB33", token)
        .publish("ghcr.io/kgb33/blog.kgb33.dev")
    )


@function
def build(dir: dagger.Directory) -> dagger.Container:
    return (
        dagger.wolfi()
        .base()
        .with_packages(["go", "git", "npm", "nodejs"])
        .container()
        .with_file("/bin/hugo", hugo_extended())
        .with_directory(
            "/blog",
            dir,
            exclude=[
                "node_modules",
                "public",
                "build.cue",
                "cue.mod",
                "themes",
                ".envrc",
            ],
        )
        .with_workdir("/blog")
        .with_exec(["hugo", "mod", "get"])
        .with_exec(["hugo", "mod", "npm", "pack"])
        .with_exec(["npm", "install"])
        .with_exposed_port(1313)
        .with_label(
            "org.opencontainers.image.source", "https://github.com/kgb33/blog.kgb33.dev"
        )
    )


@function
def hugo_extended(tag: str = "latest") -> dagger.File:
    return (
        dagger.wolfi()
        .base()
        .with_package("go")
        .container()
        .with_env_variable("CGO_ENABLED", "1")
        .with_exec(
            [
                "go",
                "install",
                "-tags",
                "extended",
                f"github.com/gohugoio/hugo@{tag}",
            ]
        )
        .file("/root/go/bin/hugo")
    )
