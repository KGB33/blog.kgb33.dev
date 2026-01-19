package main

import (
	"context"
	"dagger/blog/internal/dagger"
)

type Blog struct {
	Src  *dagger.Directory
}

func New(
	// +defaultPath="."
	// +ignore=["*", "!content/", "!static/", "!templates/", "!sass/", "!config.toml"]
	src *dagger.Directory,
) *Blog {
	return &Blog{
		Src:  src,
	}
}

func (m *Blog) Build(
	ctx context.Context,
) *dagger.Container {
	return m.BuildEnv(ctx).
		WithDirectory(".", m.Src).
		WithExec([]string{"zola", "build"})
}

func (m *Blog) BuildEnv(
	ctx context.Context,
) *dagger.Container {
	return dag.Container().
		From("ghcr.io/getzola/zola:v0.22.0")
}

func (m *Blog) Prod(
	ctx context.Context,
	// +defaultPath="Caddyfile"
	caddy *dagger.File,
) *dagger.Container {
	return dag.Container().
		From("caddy").
		WithExposedPort(1313).
		WithFile("/etc/caddy/Caddyfile", caddy).
		WithDirectory("/var/www/html", m.Build(ctx).Directory("public"))
}

func (m *Blog) Publish(
	ctx context.Context,
	// +defaultPath="Caddyfile"
	caddy *dagger.File,
	token *dagger.Secret,
) (string, error) {
	return m.Prod(ctx, caddy).WithRegistryAuth("ghcr.io", "KGB33", token).Publish(ctx, "ghcr.io/kgb33/blog.kgb33.dev")
}
