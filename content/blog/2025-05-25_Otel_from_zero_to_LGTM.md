---
title: "OTel stuff"
pubDate: "2025-06-13"
tags: ["nix", "homelab"]

draft: true
---

# Table of Contents

- Instrumenting a Rust App
  - Logs
  - Metrics 
  - Traces

- Grafana LGTM Stack overview
  - Alloy
  - Mirir
  - Loki
  - Tempo
  - Grafana

# Instrumenting a Rust App

We'll be instrumenting my Discord bot
[`KGB33/RoboShpee`](https://github.com/KGB33/RoboShpee). Its a simple rust
application that listens on a WebSocket connection for incoming user
interactions.


### Observably overview

An observable application is one where there is insight into the events within the application.
An event is anything that developers might want to observe.

Events become observable through a combination of Metrics, Logs, and Traces (the "three pillars of Observably").

Metrics are aggregations of events. Think 'requests per second', 'current
active users', or '5XX errors on endpoint XYZ compared to last hour'.

Logs are a specific event. Think logging account creation, or `println!("In
here!");`. The latter is still a log (it represents a specific event that
someone is interested in), its just not very useful.

Lastly, Traces focus on how long an event took. Think of them as timing how
long creating an account took, including breaking out database calls and
whatever function "In Here!" took to complete. Distributed tracing - not
covered in this post - allows connecting events across services too. Think of
connecting a button click on a website to the API and database calls it
eventually causes.

### Wait, What is RoboShpee?

RoboShpee hijacks Discords built-in role system to allow users to "subscribe"
to games they want to play. If I wanted to get a squad going for Hell Divers,
rather than tagging individual people, I could tag the `HellDivers` role, and
everyone with the role would get a ping.

Its basically the "Customize" section from community servers (but RoboShpee
came first!)

![] Spokane Tech discord Customize here

## What are we Collecting

Lets focus on one possible user interaction: Adding a role. 
For this interaction, there are three events we want to have insight into:
  - **Trace** the autocomplete interaction.
  - **Metric** & **Trace** When a Command is called.
  - **Log** When the bot assigns a role.

![] Sequence Diagram here

The rough code with error handling removed is as follows:

```rust
/// Adds a role
#[poise::command(slash_command, prefix_command, track_edits, category = "Roles")]
async fn add(
    ctx: Context<'_>,
    #[description = "Role to add"]
    #[autocomplete = "autocomplete_role"]
    role_name: String,
) -> Result<(), Error> {
    let Some(role) = get_roles(&ctx)
    else {
        return ctx.say(format!("The role '{role_name}' does not exist or cannot be managed.")).await?;
    };
    ctx.author_member()
        .add_role(ctx.http(), role.id)
        .await?;
    ctx.say(format!("Added {:?}", role.name)).await?;
    Ok(())
}

async fn autocomplete_role<'a>(ctx: Context<'_>, partial: &'a str) -> impl Stream<Item = String> {
    let partial_lower = partial.to_lowercase();
    futures::stream::iter(get_roles(&ctx).unwrap())
        .filter(move |r| futures::future::ready(r.name.to_lowercase().starts_with(&partial_lower)))
        .map(|r| r.name)
}
```

## Logs

Our discord bot is deployed as a Systemd service, so we can just log to
standard out and Systemd-journal will manage the logs, and our exporter (more
on that later) has Systemd-journal integrations.

In Rust, the `log` crate is used to provide a logging facade, and we'll use
`tokio/tracing-log` for the backend.

```
cargo add tracing_log log
```

and initialize the facade:

```rust
use tracing_log::LogTracer;

#[tokio::main]
async fn main() {
    LogTracer::init().unwrap();
}
```

Then just use the `log::info!` macro:

```rust
/// Adds a role
#[poise::command(slash_command, prefix_command, track_edits, category = "Roles")]
async fn add(..) -> Result<(), Error> {

    log::info!(format!("Added role '{:?}' to user '{:?}'", role.name, ctx.author.name));

    ctx.say(format!("Added {:?}", role.name)).await?;
    Ok(())
}
```

## Metrics

 > Numerical data, devoid of context for each individual event

## Traces

> Following an event's path through the app

A Trace is a collection of spans; Spans are ... and are made up of multiple hierarchical spans; 
