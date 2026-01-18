---
title: "Deploying `blog.kgb33.dev`"
description: "Hugo quick-start"
pubDate: "2021-12-17"
tags: ["hugo", "nginx", "letsEncrypt", "CI/CD", "githubActions", "npm"]
---

This post will mostly mirror Hugo's [quickstart guide][hugo-qs]. With a few differences:
the theme and customization will be more specific, and will include the steps to get
Hugo into an production environment, including CI/CD and Let's Encrypt certificates.

<!--more-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Step 0 - Installing Hugo](#step-0---installing-hugo)
- [Step 1 - Setting Up the Theme](#step-1---setting-up-the-theme)
    - [Theme Installation](#theme-installation)
    - [Json Resume](#json-resume)
- [CI/CD](#cicd)
  - [Pre-commit](#pre-commit)
  - [Github Actions](#github-actions)
    - [Check Dead Links](#check-dead-links)
- [Production](#production)
  - [Production Environment](#production-environment)
  - [Systemd Service](#systemd-service)
  - [Nginx Reverse Proxy](#nginx-reverse-proxy)
    - [Lets Encrypt Auto-certs via Cloudflare DNS](#lets-encrypt-auto-certs-via-cloudflare-dns)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Step 0 - Installing Hugo

To start, install Hugo from [here](https://gohugo.io/getting-started/installing)
at [gohugo.io](https://gohugo.io).

Then, create a new project and move into the directory it creates.

```Shell
hugo new site cite-name
cd cite-name
```

Then create a post.

```shell
hugo new posts/hello-world.md
echo Hello World! >> content/posts/hello-world.md
```

And start the development server with drafts enabled by running `hugo server -D`.

```console
❯ hugo server -D
Start building sites …
hugo v0.89.4+extended linux/amd64 BuildDate=unknown

                   | EN
-------------------+-----
  Pages            | 12
  Paginator pages  |  0
  Non-page files   |  0
  Static files     |  2
  Processed images |  0
  Aliases          |  3
  Sitemaps         |  1
  Cleaned          |  0

Built in 17 ms
Watching for changes in /home/kgb33/Code/blog.kgb33.dev/{archetypes,content,data,layouts,static,themes}
Watching for config changes in /home/kgb33/Code/blog.kgb33.dev/config.toml
Environment: "development"
Serving pages from memory
Running in Fast Render Mode. For full rebuilds on change: hugo server --disableFastRender
Web Server is available at http://localhost:1313/ (bind address 127.0.0.1)
Press Ctrl+C to stop
```

By default it should run on <http://localhost:1313>, and hot-reload.
Open a new terminal and navigate back to the `cite-name` folder to set up git.

```console
git init

cat <<EOF > .gitignore
# Hugo
public/
*.lock
_gen/
hugo_stats.json

# Node
node_modules/
EOF
```

Hugo creates a bunch of stuff, and its hard to tell what is needed in source control
and what can (and will) be recreated. Be aware when adding files to git, and update
`.gitignore` accordingly.

# Step 1 - Setting Up the Theme

### Theme Installation

From the `cite-name` directory created in the previous step, clone the [`schnerring/hugo-theme-gruvbox`][theme] theme into a sub-module.
Make sure to get the `themes/gruvbox` directory on the end of the command.

```console
git submodule add git@github.com:schnerring/hugo-theme-gruvbox.git themes/gruvbox
```

Next, initialize a [hugo module][hugo-mod]. This piggybacks of go modules
and will create a `go.mod` and `go.sum`.

```console
hugo mod init cite-name
```

Then, open `config.toml`.

First, change the default `baseURL`, `languageCode` and, `title`.
Then add a new line defining the theme.

```toml
baseURL = 'https://blog.kgb33.dev'
languageCode = 'en-us'
title = ""
theme = "gruvbox"
```

Add the following so the theme can resolve directories correctly.

> Check <https://github.com/schnerring/hugo-theme-gruvbox/issues/16> to see if a better module specification has been implemented first!

```toml
[markup]
  # (Optional) To be able to use all Prism plugins, the theme enables unsafe
  # rendering by default
  #_merge = "deep"

[build]
  # The theme enables writeStats which is required for PurgeCSS
  _merge = "deep"

# This hopefully will be simpler in the future.
# See: https://github.com/schnerring/hugo-theme-gruvbox/issues/16
[module]
  [[module.imports]]
    path = "github.com/schnerring/hugo-mod-github-readme-stats"
  [[module.imports]]
    path = "github.com/schnerring/hugo-mod-json-resume"
    [[module.imports.mounts]]
      source = "data"
      target = "data"
    [[module.imports.mounts]]
      source = "layouts"
      target = "layouts"
    [[module.imports.mounts]]
      source = "assets/css/json-resume.css"
      target = "assets/css/critical/44-json-resume.css"
  [[module.mounts]]
    # required by hugo-mod-json-resume
    source = "node_modules/simple-icons/icons"
    target = "assets/simple-icons"
  [[module.mounts]]
    source = "assets"
    target = "assets"
  [[module.mounts]]
    source = "layouts"
    target = "layouts"
  [[module.mounts]]
    source = "static"
    target = "static"
  [[module.mounts]]
    source = "node_modules/prismjs"
    target = "assets/prismjs"
  [[module.mounts]]
    source = "node_modules/prism-themes/themes"
    target = "assets/prism-themes"
  [[module.mounts]]
    source = "node_modules/typeface-fira-code/files"
    target = "static/fonts"
  [[module.mounts]]
    source = "node_modules/typeface-roboto-slab/files"
    target = "static/fonts"
  [[module.mounts]]
    source = "node_modules/@tabler/icons/icons"
    target = "assets/tabler-icons"
```

Finally, run the following commands to initialize the theme,
then restart the server.

```console
hugo mod get
hugo mod npm pack
npm install

hugo server -D
```

### Json Resume

This theme uses [`schnerring/hugo-mod-json-resume`][theme-json-resume] for a bunch of things,
including populating the sidebar. To personalize the theme create a new file `data/json_resume/en.json`

> This file must match the spec defined by [JSON Resume][json-resume].

```json
{
  "$schema": "https://raw.githubusercontent.com/jsonresume/resume-schema/v1.0.0/schema.json",
  "basics": {
    "name": "Kelton Bassingthwaite",
    "image": "https://avatars.githubusercontent.com/u/17833726?v=4",
    "email": "KeltonBassingthwaite@gmail.com",
    "url": "https://blog.kgb33.dev",
    "profiles": [
      {
        "network": "Github",
        "username": "KGB33",
        "url": "https://github.com/KGB33"
      }
    ]
  }
}
```

# CI/CD

## Pre-commit

[`pre-commit`][pre-commit] is an awesome python cli tool
to manage git hooks. I recommend installing it via
[`pipx`][pipx]: `pipx install pre-commit`.

Then, create a new file `.pre-commit-config.yaml`.

```yaml
# See https://pre-commit.com for more information
# See https://pre-commit.com/hooks.html for more hooks
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.1.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-toml
  - repo: https://github.com/thlorenz/doctoc
    rev: v2.1.0
    hooks:
      - id: doctoc
```

Install the hooks to run on every (local) git commit via `pre-commit install`
Then, to immediately run the hooks on all files use `pre-commit run --all-files`.
To force a commit when the hooks fail use `git commit --no-verify`

## Github Actions

If `pre-commit` is for local hooks, Github actions is for remote hooks.
Each action is defined by a file `.github/workflows/<hook-name>.yaml`.
Checkout <https://docs.github.com/en/actions/quickstart> for more info.

### Check Dead Links

[gaurav-nelson/github-action-markdown-link-check][actions-md-link] is exactly what it sounds like.
Too add it create a new file, `.github/workflows/md-link-check.yaml` with the following content.

```yaml
name: Check Markdown links

on:
  workflow_dispatch:
  schedule:
  # Run every Sunday at midnight
  - cron: "0 0 * * 0"

jobs:
  markdown-link-check:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - uses: gaurav-nelson/github-action-markdown-link-check@v1
      with:
        use-quiet-mode: 'yes'
        use-verbose-mode: 'yes'
		config-file: 'mlc_config.json'
```

Where `mlc_config.json` contains:

```json
{
  "ignorePatterns": [
    {
      "pattern": "^https?://localhost*"
    }
  ]
}
```

Once the above two files are committed and pushed to Github, navigate to
the Actions tab, click "Check Markdown Links" in the left column, then hit
the "Run workflow" drop down menu. The action will also run automatically at
midnight every Sunday and Github will send you an email if it fails.

# Production

## Production Environment

This website is ran off of an Ubuntu 21.10 LXE container managed by Proxmox.
Once the container is up and running make sure to preform an update and download `git` and `curl`.

```console
apt update && \
apt upgrade -y && \
apt install git curl golang -y
```

Next, download and install the latest binary release for Hugo (extended) from the [releases][hugo-releases] page.

```console
export HUGO_VER="0.91.2" && \
curl -L https://github.com/gohugoio/hugo/releases/download/v${HUGO_VER}/hugo_extended_${HUGO_VER}_Linux-64bit.deb -o hugo.deb && \
apt install ./hugo.deb
```

Then do the same for the latest NodeJS version.

```console
export NODE_VER="17.3.0" && \
curl -L https://nodejs.org/dist/v${NODE_VER}/node-v${NODE_VER}-linux-x64.tar.gz -o node.tar.gz && \
tar -C /usr/local --strip-components 1 -xzf node.tar.gz && source ~/.bashrc
```

Then clone the blog repository and install dependencies.

```console
git clone --recurse-submodules --remote-submodules https://github.com/KGB33/blog.kgb33.dev.git && \
cd blog.kgb33.dev && \
hugo mod get && \
hugo mod npm pack && \
npm install
```

> Note: At least one published post is required for Hugo build successfully with this theme.

## Systemd Service

Systemd will be responsible for managing the Hugo server. This will ensure that
Hugo will restart after a reboot or crash. First, create a systemd unit file at `/etc/systemd/system/hugoserver.service`.

```toml
[Unit]
Description=Hugo-Server

[Service]
ExecStart=/usr/local/bin/hugo server --bind=0.0.0.0
WorkingDirectory=/root/blog.kgb33.dev/
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

## Nginx Reverse Proxy

I have Nginx running as a reverse proxy so I can serve separate sub-domains from the same public IP address.

To serve the blog add the following file `/etc/nginx/sites-avalable/blog`

```nginx
server {
        server_name blog.kgb33.dev;

        location / {
            proxy_pass  http://10.0.0.106:1313;
			proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        	proxy_set_header Host $http_host;
        	proxy_set_header X-Forwarded-Proto https;
        	proxy_redirect off;
        	proxy_http_version 1.1;
        }
}
```

Then enable the site using a symlink.

```console
sudo ln -s sites-available/blog sites-enabled/blog
```

### Lets Encrypt Auto-certs via Cloudflare DNS

Install and configure certbot using their [docs][certbot-docs] and setup a DNS record for
`blog.kgb33.dev`. Then run the following command to get the certs from Lets Encrypt.
Where `cloudflare.ini` contains the Cloudflare api token.

```console
sudo certbot -i nginx --dns-cloudflare --dns-cloudflare-credentials ~/cloudflare.ini -d blog.kgb33.dev
```

Lastly, restart nginx.

```console
systemctl restart nginx
```

Then checkout <https://blog.kgb33.dev>!

<!--- Links -->

[hugo-qs]: https://gohugo.io/getting-started/quick-start/
[hugo-mod]: https://gohugo.io/hugo-modules/use-modules/
[hugo-releases]: https://github.com/gohugoio/hugo/releases
[theme]: https://github.com/schnerring/hugo-theme-gruvbox
[theme-json-resume]: https://github.com/schnerring/hugo-mod-json-resume
[json-resume]: https://jsonresume.org/
[pre-commit]: https://pre-commit.com/
[pipx]: https://pipx.pypa.io/stable/
[actions-md-link]: https://github.com/gaurav-nelson/github-action-markdown-link-check
[certbot-docs]: https://certbot.eff.org/
