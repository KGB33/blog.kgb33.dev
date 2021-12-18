---
title: "Getting Started with Hugo"
date: "2021-12-17T16:22:11-08:00"
tags: ["hugo",]

draft: true
---

This post will mostly mirror Hugo's [quickstart guide][hugo-qs]. With a few differences:
the theme and customization will be more specific, and will include the steps to get 
Hugo into an production environment, including CI/CD and Let's Encrypt certificates.

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
    "profiles": [{
      "network": "Github",
      "username": "KGB33",
      "url": "https://github.com/KGB33"
    }]
  }
}
```

# CI/CD

### Pre-commit 
  - Spell check 
  - markdown auto-format (esp. line-length)
  - Check for dead links 

### Auto Deployment from `main`

### ACME/Lets Encrypt Auto-certs via cloudflare DNS

## Resources

<!--- Links -->
[hugo-qs]: https://gohugo.io/getting-started/quick-start/
[hugo-mod]: https://gohugo.io/hugo-modules/use-modules/
[theme]: https://github.com/schnerring/hugo-theme-gruvbox
[theme-json-resume]: https://github.com/schnerring/hugo-mod-json-resume
[json-resume]: https://jsonresume.org/
