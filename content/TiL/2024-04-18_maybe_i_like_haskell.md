---
title: "`Maybe` I Like Haskell"
date: 2024-04-18T07:43:02-07:00
tags: ["TiL", "haskell", "rust"]

draft: false
---

# Problem

I'm writing a CLI tool - called [`hmm`](https://github.com/KGB33/hmm) - in Haskell that manages tmux
sessions. By default, I want it to open a session named after the current git
context. I.e. if I'm working on branch `bar` in repo `foo` I want the session
to be named `foo-bar`. However, on rare occasions, I might want to override
either value. To do this, I have optional command line flags 

```
$ hmm

Usage: hmm [-r|--repo REPO] [-b|--branch BRANCH]

  Manages tmux sessions.

Available options:
  -r,--repo REPO           First part of the tmux session name.
  -b,--branch BRANCH       Second part of the tmux session name.
  -h,--help                Show this help text
```

These options are defined as parsers, then collected into a `Options` object.
Don't worry about what each cryptic symbol means, just know that `branch` is a
parser that will parse an optional CLI flag into a `Maybe String`.

```haskell
branch :: Parser (Maybe String)
branch =
  optional $
    strOption
      ( long "branch"
          <> short 'b'
          <> metavar "BRANCH"
          <> help "Second part of the tmux session name."
      )

data Options = Options
  { optRepo :: Maybe String,
    optBranch :: Maybe String
  }
```


Importantly, because my defaults are calculated at run-time using sub-process
(i.e. `git`) they are 'impure' have the type `IO String`, **not** `String` like
the parser expects. This means I cannot add the default values to the parser,
meaning it needs to parse to a `Maybe String` type to implement the
functionality I want. 

## `Maybe` Sidebar
In Haskell, `Maybe` is a lot like Rust's `Option<T>` (especially if you adjust the formatting a bit).

```haskell
data Maybe T = 
    Nothing 
    | Just (T)
```

```rust
enum Option<T> {
    None,
    Some(T),
}
```

These types both represent the computational context of a nullable value.
They both encapsulate some value - or the lack there of. They force surrounding
code to deal with the potentially null value. Not only that, but they also provide a
way to turn `Maybe a` into `Maybe b` without caring if the encapsulated value
is null.

# Pattern Matching solutions

The first and most obvious solution solutions was to pattern match on every
combination of inputs, for a total of four function signatures. However, this
will quickly grow out of hand as more flags are added - at a rate of $n^2$
where n is the number of optional inputs. 

```haskell
entrypoint :: Options -> IO ()
entrypoint Options (r b) = _ -- Both Options provided.
entrypoint Options (r Nothing) = _ -- Only Repo Provided.
entrypoint Options (Nothing b) = _ -- Only Branch Provided.
entrypoint Options (Nothing Nothing) = _ -- No options provided.
```

The second solution was to build up the entry point by currying partial
functions for each option. In the end, I never implemented this solution
because it didn't seem quite right; how would you elegantly curry functions
based on what they're called with? So in the end I looked for different options. 

# Solution

The final solution was surprisingly simple. Haskell has a function `maybe`
(lowercase 'm') that is a lot like Rust's `Option::map_or`. The docs for `maybe` and both definitions
are below. Note that both functions sill return a value wrapped in a `Maybe`/`Option`.

> The `maybe` function takes a default value, a function, and a `Maybe` value. If
> the `Maybe` value is `Nothing`, the function returns the default value.
> Otherwise, it applies the function to the value inside the `Just` and returns
> the result. - [Hackage](https://hackage.haskell.org/package/base-4.20.0.0/docs/Prelude.html#v:maybe)

```haskell
maybe :: b -> (a -> b) -> Maybe a -> b
maybe n _ Nothing  = n
maybe _ f (Just x) = f x
```

```rust
pub fn map_or<U, F>(self, default: U, f: F) -> U
where
    F: FnOnce(T) -> U,
{
    match self {
        Some(t) => f(t),
        None => default,
    }
}
```

So, my entry point is as follows:

```haskell
hmm :: Options -> IO ()
hmm options = do
  r <- maybe computeDefaultRepo return (optRepo options)
  b <- maybe computeDefaultBranch return (optBranch options)
  let sessionName :: String = r ++ "-" ++ b
```

A few things to note:
  - `r` and `b` have types `String`
  - `computeDefaultXYZ` has type `IO String`

Now, lets break apart `maybe computeDefaultRepo return (optRepo options)`. From
the signature above, `b` corresponds to `computeDefaultRepo`, so it has type
`IO String`. Next, `return` is the function that maps `(a -> b)`; It has the
signature `return :: a -> m a`. Lastly, `(optRepo options)` is the `Maybe
String` monad from the parser. Plugging our known types into the `maybe` signature we get:

  - `b` = `IO String`
  - `a` = `String`
  - `maybe :: (IO String) -> (String -> (IO String)) -> Maybe String -> IO String`

Now, we've solved our original problem and converted the default and provided
values to the same type! Just one last issue. I said that `r` and `b` have
types `String`, but I also said that the `maybe` function returns a `IO
String`. This is where the `do` and `<-` notation come in. They allow us to
extract the contents from the `IO` monad on the condition that we return a
`IO` monad. 

# Summary

Overall, I really enjoyed writing Haskell. It felt more like programming
*types* and *structure* rather than programming *business logic* - a breath of
fresh air from the Python I'm used to. At the same time Haskell's compiler was
a lot less picky to work with than Rust's; although the short and simple nature
of this program also probably helped. 
