import dagger
from dagger import function, dag, object_type

ENTRY_POINT = [
    "/bin/hugo",
    "server",
    "--bind=0.0.0.0",
    "--baseURL=https://blog.kgb33.dev/",
    "--appendPort=false",
    "--disableLiveReload=true",
]


@object_type
class BlogBuild:

    @function
    def prod(self, dir: dagger.Directory) -> dagger.Container:
        """
        Builds a production-ready container.
        """
        return self.build(dir).with_entrypoint(ENTRY_POINT).without_default_args()


    @function
    async def run(self, dir: dagger.Directory) -> dagger.Service:
        """
        Runs the blog locally.
        """
        return self.build(dir).with_exec(ENTRY_POINT).as_service()


    @function
    async def publish(self, dir: dagger.Directory, token: dagger.Secret) -> str:
        """
        Publishes the production ready container to ghcr.io/kgb33/blog.kgb33.dev.
        """
        return await (
            self.prod(dir)
            .with_registry_auth("ghcr.io", "KGB33", token)
            .publish("ghcr.io/kgb33/blog.kgb33.dev")
        )


    @function
    def build(self, dir: dagger.Directory) -> dagger.Container:
        """
        Builds a debug-ready, tty-ready, contianer.
        """
        return (
            dag.wolfi()
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


def hugo_extended(tag: str = "latest") -> dagger.File:
    return (
        dag.wolfi()
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
