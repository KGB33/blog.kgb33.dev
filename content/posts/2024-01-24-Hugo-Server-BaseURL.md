---
title: "TiL... `hugo server` ignores variables set in `config.toml`"
date: 2024-01-24T00:00:00-08:00
tags: ["TiL", "Hugo"]

draft: false
---

<!--more-->

I tried out [Bernard](https://bernard.app/) on the live blog, it reported hundreds of bad links. Almost
every single one linked to `localhost:1313` - Hugo's default baseURL and port. Even though I had set `baseURL` in
my `config.toml`.


```toml
baseURL = 'https://blog.kgb33.dev'
...
```

Luckily, the fix was fairly simple, just pass the config variables as flags to `hugo server`.
Plus, I probably don't need live reloading on the live server...

```diff
 ENTRY_POINT = [
     "/bin/hugo",
     "server",
     "--bind=0.0.0.0",
+    "--baseURL=https://blog.kgb33.dev/",
+    "--appendPort=false",
+    "--disableLiveReload=true",
 ]
```
