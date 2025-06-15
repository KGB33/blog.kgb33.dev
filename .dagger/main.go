package main

import (
	"context"
	"dagger/blog/internal/dagger"
)

type Blog struct {
	Src  *dagger.Directory
	Pkg  *dagger.File
	Lock *dagger.File
}

func New(
	// +defaultPath="."
	// +ignore=["*", "!src/", "!public/", "!astro.config.mjs", "!tsconfig.json"]
	src *dagger.Directory,
	// +defaultPath="package.json"
	pkg *dagger.File,
	// +defaultPath="bun.lock"
	lock *dagger.File,
) *Blog {
	return &Blog{
		Src:  src,
		Pkg:  pkg,
		Lock: lock,
	}
}

func (m *Blog) Build(
	ctx context.Context,
) *dagger.Container {
	return m.BuildEnv(ctx).
		WithDirectory(".", m.Src).
		WithExec([]string{"bun", "run", "build"})
}

func (m *Blog) BuildEnv(
	ctx context.Context,
) *dagger.Container {
	bunCache := dag.CacheVolume("bun")
	return dag.Container().
		From("oven/bun:1").
		WithFile("bun.lock", m.Lock).
		WithFile("package.json", m.Pkg).
		WithMountedCache("/root/.bun", bunCache).
		WithExec([]string{"bun", "install", "--frozen-lockfile", "--production"})
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
		WithDirectory("/var/www/html", m.Build(ctx).Directory("dist"))
}

func (m *Blog) Publish(
	ctx context.Context,
	// +defaultPath="Caddyfile"
	caddy *dagger.File,
	token *dagger.Secret,
) (string, error) {
	return m.Prod(ctx, caddy).WithRegistryAuth("ghcr.io", "KGB33", token).Publish(ctx, "ghcr.io/kgb33/blog.kgb33.dev")
}
