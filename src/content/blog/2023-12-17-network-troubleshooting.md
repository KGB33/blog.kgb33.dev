---
title: "Troubleshooting Failing Commands"
pubDate: "2023-12-17"
tags: [k8s, network, roboshpee]

draft: false
---

I created a new command on my Discord bot ([PR #16](https://github.com/KGB33/RoboShpee/pull/16))
that fetches the status of the Minecraft servers running on
`minecraft.kgb33.dev`. When running locally it worked perfectly, but when
running in production it fails silently. This post outlines the debugging steps
I took to solve the issue.

<!--more-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Problem Overview](#problem-overview)
  - [Network/Host Background](#networkhost-background)
- [Data](#data)
  - [Roboshpee Logs](#roboshpee-logs)
  - [Hubble logs](#hubble-logs)
  - [`minecraft.kgb33.dev` TCP Dump](#minecraftkgb33dev-tcp-dump)
  - [`ping`-pong](#ping-pong)
  - [Routes out of `minecraft`](#routes-out-of-minecraft)
- [Fix](#fix)
  - [Part 1: Proxmox Tagging](#part-1-proxmox-tagging)
  - [Part 2: Ubuntu Untagging](#part-2-ubuntu-untagging)
- [Summary](#summary)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Problem Overview

The new `/minecraft` command fails silently when the Discord bot, Roboshpee, is running
in Kubernetes. However, it works when the bot is run on my development laptop.

## Network/Host Background

First, it's important to understand the network and hosts I'm debugging.
Roboshpee is running in a Kubernetes cluster on virtualized Talos nodes. The
[`iqt`](https://github.com/KGB33/iqt) server its trying (spoilers) to connect to is
hosted on `minecraft.kgb33.dev`.

My VLANs and subnets are correlated. The third octet of the subnet corresponds to
the VLAN tag; e.g. `10.0.9.0/24` is on VLAN 9.

![Network Diagram](../../static/images/posts/2023-12-17/MinecraftRoboshpeeDiagram.png)

# Data

## Roboshpee Logs

First place to check is the bot's logs:

```cmd
2023-12-16 18:42:37,387 | gql.transport.aiohttp | INFO | >>> {"query": "query IntrospectionQuery { ... }"}
```
In comparison to the working log below, the bot attempts to contact the `iqt`
server, but gets no response.

```cmd
2023-12-16 10:54:48,034 | gql.transport.aiohttp | INFO | >>> {"query": "query IntrospectionQuery { ... }"}
2023-12-16 10:54:48,116 | gql.transport.aiohttp | INFO | <<< {"data":{"__schema": ... }}

2023-12-16 10:54:48,123 | gql.transport.aiohttp | INFO | >>> {"query": "..."}
2023-12-16 10:54:48,164 | gql.transport.aiohttp | INFO | <<< {"data":{ ... }}
```

## Hubble logs

Ok, so the bot is making the request. Is it able to leave the Kubernetes
cluster? That is the *only* thing that has changed between production and dev.
Oddly enough, it looks like it is able to leave. Cillium's Hubble UI shows
several `SYN` packets being routed outside the cluster but nothing coming back.

![Hubble Logs](../../static/images/posts/2023-12-17/hubble_rshpee_logs.png)

## `minecraft.kgb33.dev` TCP Dump

Ok, the bot is making the request, and it's leaving the cluster. Maybe it's not making
it to `minecraft.kgb33.dev`.

```cmd
$ tcpdump port 4807
listening on ens18, link-type EN10MB (Ethernet), snapshot length 262144 bytes
11:15:01.271252 IP 10.0.9.22.37278 > minecraft.4807: Flags [S], seq 1652160953, win 64860, options [mss 1410,sackOK,TS val 3297435160 ecr 0,nop,wscale 7], length 0
11:15:02.288460 IP 10.0.9.22.37278 > minecraft.4807: Flags [S], seq 1652160953, win 64860, options [mss 1410,sackOK,TS val 3297436178 ecr 0,nop,wscale 7], length 0
11:15:04.304338 IP 10.0.9.22.37278 > minecraft.4807: Flags [S], seq 1652160953, win 64860, options [mss 1410,sackOK,TS val 3297438194 ecr 0,nop,wscale 7], length 0
```

Nope, those same `SYN` packets are making it to their destination. But nothing is comming back.

## `ping`-pong

Because it worked on my dev laptop, I assumed that the issue was with
Kubernetes networking, but it looks like `minecraft` cannot talk back to `gwen`

```cmd
kgb33@minecraft:~$ ping 10.0.9.22
PING 10.0.9.22 (10.0.9.22) 56(84) bytes of data.
From 10.0.9.120 icmp_seq=1 Destination Host Unreachable
From 10.0.9.120 icmp_seq=2 Destination Host Unreachable
From 10.0.9.120 icmp_seq=3 Destination Host Unreachable
From 10.0.9.120 icmp_seq=4 Destination Host Unreachable
From 10.0.9.120 icmp_seq=5 Destination Host Unreachable
From 10.0.9.120 icmp_seq=6 Destination Host Unreachable
From 10.0.9.120 icmp_seq=7 Destination Host Unreachable
^C
--- 10.0.9.22 ping statistics ---
8 packets transmitted, 0 received, +7 errors, 100% packet loss, time 7117ms
```

## Routes out of `minecraft`

Oddly enough, packets to the `10.0.9.0/24` subnet were routed on the `ens18` interface,
whereas everything else (inculding `10.0.7.36`) was tagged as VLAN 9.

```cmd
kgb33@minecraft:~$ ip route get 10.0.9.22
10.0.9.22 dev ens18 src 10.0.9.120 uid 1000
    cache
kgb33@minecraft:~$ ip route get 10.0.7.36
10.0.7.36 via 10.0.9.1 dev ens18.9 src 10.0.9.120 uid 1000
    cache
```

# Fix

The fix has two parts:
  - Tag the virtual interface in Proxmox.
  - Untag the interface in Ubuntu.

I could just change the configuration so everything is routed through
`ens18.9`, but for consistancy I'm tagging everything in Proxmox.

## Part 1: Proxmox Tagging

This part was supper easy, just edit the network device and add a "9" to the
right text field.

## Part 2: Ubuntu Untagging

This step took a bit longer as I have very little experience using NetPlan.
I basically removed the VLAN configuration and moved the address, nameserver,
and route information to the Ethernet section.

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens18:
      dhcp4: no
      addresses:
        - 10.0.9.120/24
      nameservers:
        addresses:
          - 10.0.8.53
          - 1.1.1.1
          - 1.0.0.1
      routes:
        - to: default
          via: 10.0.9.1
```

# Summary

`minecraft` could not route packets to any device on VLAN-9, i.e. the
`10.0.9.0/24` subnet. This presented itself as the `iqt` server failing to
respond to the Discord bot. To fix the issue I tagged the virtual port in Proxmox,
and removed the VLAN configuration from the Netplan config on `minecraft`.
