---
title: "Regex Capture Groups: Restructure text using NeoVim"
pubDate: "2024-07-25"
tags: ["neovim", "regex"]

draft: false
---

One small issue I've encountered lately is being able to quickly and
automatically convert text from one structured form to another. 

My go-to tool for this has been macros, but regex capture groups should work just as well. 

<!--more-->

# Problem Statement

The example for this post will be converting (parts of) a Poetry-style
`pyproject.toml` to a PEP621 style one, specifically, the dependency
declarations.


Transform this:

```toml
# Original
[tool.poetry.dependencies]
"discord.py" = "^2.4.0"
prettytable = "^3.10.2"
fuzzywuzzy = {extras = ["speedup"], version = "^0.18.0"}
requests = "^2.32.3"
cashews = "^6.2.0"
gql = {extras = ["aiohttp"], version = "^3.4.1"}
```

Into this:
```toml
# New
dependencies = [
    "discord.py>=2.4.0",
    "prettytable>=3.10.2",
    "fuzzywuzzy[speedup]>=0.18.0",
    "requests>=2.32.3",
    "cashews>=6.2.0",
    "gql[aiohttp]>=3.4.1",
]
```

# Regex Capture Groups 101

Capture groups allow you to store matched sections of the input string and use
them elsewhere, in our case, as part of a replacement over the matched string.

There are two types of capture groups, named and unnamed, however Vim only
implements unnamed capture groups.

|    -    | Capture        | Access    |
| ------- | -------------- | --------- |
| Unnamed | `\(...\)`      | `\n`      |

> Note: Unnamed capture groups are indexed starting at 1.

# Example 1


### Step 0

Starting:

```toml
# Original
[tool.poetry.dependencies]
"discord.py" = "^2.4.0"
prettytable = "^3.10.2"
fuzzywuzzy = {extras = ["speedup"], version = "^0.18.0"}
requests = "^2.32.3"
cashews = "^6.2.0"
gql = {extras = ["aiohttp"], version = "^3.4.1"}
```
### Step 1

Normalize the data:
  - Remove the TOML table header
  - Move `fuzzywuzzy` to the bottom.
  - Remove the quotes around `"discord.py"`

```toml
discord.py = "^2.4.0"
prettytable = "^3.10.2"
requests = "^2.32.3"
cashews = "^6.2.0"
gql = {extras = ["aiohttp"], version = "^3.4.1"}
fuzzywuzzy = {extras = ["speedup"], version = "^0.18.0"}
```

### Step 2

Convert the top four:
  - Highlight the lines
  - `:'<,'>s/\(.*\) = "^\(\d*\.\d*\.\d*\)"/"\1>=\2",`
    - `:'<,'>s/` - Search and replace over visual selection.
    - ` \(.*\) = "^\(\d*\.\d*\.\d*\)"/` - Captures the dependency name in group 1, and version in group 2.
    - `"\1>=\2",` - Replaces matched string using capture groups.

> Note: `":p` pastes the contents of register `:`, which contains the last run command.
> Or use `q:` to open a buffer with all previous commands and yank from there.


```toml
"discord.py>=2.4.0",
"prettytable>=3.10.2",
"requests>=2.32.3",
"cashews>=6.2.0",
gql = {extras = ["aiohttp"], version = "^3.4.1"}
fuzzywuzzy = {extras = ["speedup"], version = "^0.18.0"}
```

### Step 3

Convert the bottom two:
  - Highlight the lines
  - `:'<,'>s/\(\w*\).*\["\(\w*\).*^\(\d*\.\d*\.\d*\)"}/"\1[\2]>=\3",`
    - `\(\w*\).*\["\(\w*\).*^\(\d*\.\d*\.\d*\)"}/` - Captures
      - `\(\w*\)` - Capture the dependency.
      - `.*\["\(\w*\)` - Eat everything up to the next `[`, then capture the extra.
      - `.*^\(\d*\.\d*\.\d*\)"}` - Eat up to the `^`, then capture the version.
    - `"\1[\2]>=\3",` - Replaces, using capture groups.

> Note: This assumes that there is only one extra per dependency.


```toml
"discord.py>=2.4.0",
"prettytable>=3.10.2",
"requests>=2.32.3",
"cashews>=6.2.0",
"gql[aiohttp]>=3.4.1",
"fuzzywuzzy[speedup]>=0.18.0",
```

### Step 4

Sort & add brackets:
  - Highlight all the dependencies.
  - `:'<,'>!sort`
  - Surround with `dependencies = [` and `]`

```toml
dependencies = [
    "cashews>=6.2.0",
    "discord.py>=2.4.0",
    "fuzzywuzzy[speedup]>=0.18.0",
    "gql[aiohttp]>=3.4.1",
    "prettytable>=3.10.2",
    "requests>=2.32.3",
]
```
