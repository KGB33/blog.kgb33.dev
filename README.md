# [blog.kgb33.dev](https://blog.kgb33.dev/)

The source for my [Hugo](https://github.com/gohugoio/hugo) based blog. Theme by
[Scherring](https://github.com/schnerring/hugo-theme-gruvbox).

# Running in Production

See the ArgoCD config [here](https://github.com/KGB33/homelab/tree/main/k8s-apps/blog-kgb33-dev)

# Running Locally

The blog is containerized using [Dagger](https://github.com/dagger/dagger).
To run locally, use `dagger -m ci call run --dir . up`:

```
❯ dagger -m ci call run --dir . up
✔ Service.up: Void 18.4s
┃ 1313/TCP: tunnel 0.0.0.0:1313 -> o3431l4qpguf0.p35ol4b6ulvlg.dagger.local:1313
  ✔ start /bin/hugo server --bind=0.0.0.0 --baseURL=https://blog.kgb33.dev/ --appendPort=false --disableLiveReload=true 18.5
  ┃ Watching for changes in /blog/{archetypes,content,data,node_modules,package.hugo.json,package.json,static}
  ┃ Watching for config changes in /blog/config.toml, /blog/go.mod
  ┃ Start building sites …
  ┃ hugo v0.122.0+extended linux/amd64 BuildDate=unknown
  ┃
  ┃
  ┃                    | EN  | DE
  ┃ -------------------+-----+-----
  ┃   Pages            | 122 |  7
  ┃   Paginator pages  |   7 |  0
  ┃   Non-page files   |   0 |  0
  ┃   Static files     |  70 | 70
  ┃   Processed images |   0 |  0
  ┃   Aliases          |  51 |  3
  ┃   Sitemaps         |   2 |  1
  ┃   Cleaned          |   0 |  0
  ┃
  ┃ Built in 1036 ms
  ┃ Environment: "development"
  ┃ Serving pages from memory
  ┃ Running in Fast Render Mode. For full rebuilds on change: hugo server --disableFastRender
  ┃ Web Server is available at https://blog.kgb33.dev/ (bind address 0.0.0.0)
  ┃ Press Ctrl+C to stop

Canceled
```

Additional CI/CD options are viewable under `dagger -m ci functions`.

```
❯ dagger -m ci functions
✔ dagger functions [0.00s]
┃ Name      Description
┃ build     Builds a debug-ready, tty-ready, contianer.
┃ prod      Builds a production-ready container.
┃ publish   Publishes the production ready container to ghcr.io/kgb33/blog.kgb33.dev.
┃ run       Runs the blog locally.
• Engine: 0d1b8c03cfe2 (version v0.9.7)
⧗ 2.64s ✔ 193 ∅ 42
```

# Contributing

Comments and Corrections - in the form of GitHub issues - are greatly
encouraged. However, PRs are not encouraged, all the content on my blog is mine.
