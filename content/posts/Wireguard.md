---
title: "Point-to-Site Wireguard Configuration"
date: 2022-03-08T09:22:17-08:00
tags: ["Wireguard", "opnsense", "networkd"]

draft: true
---

Configuring Wireguard to allow a "road-warrior" (aka point-to-site) setup
using OPNsense and systemd-networkd.

<!--more-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Generating Point Peer Keys](#generating-point-peer-keys)
- [Configuring the Site Peer](#configuring-the-site-peer)
- [Configuring the Point Peer(s)](#configuring-the-point-peers)
      - [99-wg0.netdev](#99-wg0netdev)
      - [99-wg0.network](#99-wg0network)
- [Toggling the VPN](#toggling-the-vpn)
- [Additional Resources](#additional-resources)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

> Note: Wireguard views every connection as a peer. I'll use the terms
> _client_/_point_ and _server_/_site_ to better differentiate between
> each peer.

# Generating Point Peer Keys

Keys need to be generated for each point that wants to connect
and cannot be reused.

The following commands will create the three key files a point will need
to connect to the site; A private key, a public key, and a pre-shared key.

```
$ wg genkey | (umask 0077 && tee wg-point-private.key) | wg pubkey > wg-point-public.key
$ wg genpsk | (umask 0077 && tee site-point.psk)
```

# Configuring the Site Peer

OPNsense has an excellent walk through on configuring the site
side of the VPN connection.

Follow along with [WireGuard Road Warrior Setup][opnsense-roadwarrior]
up to the configuring the client.
Make sure to note the "Tunnel Address" (`10.10.10.1/24`),
the client peer "Allowed IPs" (`10.10.10.2/32`), and the
port chosen (`51820`). These will be used later.

# Configuring the Point Peer(s)

To configure a point using `systemd-networkd` four files need to be created
in the `/etc/systemd/network/` directory.
A `XX-wg0.netdev`, `XX-wg0.network`, `wg-point-private.key`, and `site-point.psk`

> Note: Both the `*.key` and `*.psk` files contain secrets. It is recommended
> that only `root` and `systemd-network` have access to them.
>
> ```
> # chown root:systemd-network /etc/systemd/network/<KEY_FILE>
> # chmod 0640 /etc/systemd/network/<KEY_FILE>
> ```

#### 99-wg0.netdev

```toml
[NetDev]
Name=wg0
Kind=wireguard
Description=Homelab Tunnel

[WireGuard]
PrivateKeyFile=/etc/systemd/network/wg-point-private.key

[WireGuardPeer]
PublicKey=<Site Peer Public Key>
PresharedKeyFile=/etc/systemd/network/site-point.psk
Endpoint=<Site Peer IP or Domain>:<Port>
AllowedIPs=0.0.0.0/0
```

#### 99-wg0.network

Destinations under the `Route` header define what systemd-networkd routes
though the VPN.

```toml
[Match]
Name=wg0

[Network]
Address=10.10.10.2/32 # The Point Peer's address

[Route]
Gateway = 10.10.10.1 # The Site Peer's address
Destination = 10.10.10.0/24
Destination = 10.0.3.0/24
GatewayOnlink = true
```

# Toggling the VPN

By default `systemd-networkd` will route only packets that
match the Destinations defined in `99-wg0.network` through
the tunnel. However to turn off the VPN run `networkctl down wg0`.
Likewise to turn the VPN on: `networkctl up wg0`

# Additional Resources

- Elouworld -- [WireGuard (via systemd-networkd)][elouworld]
- Arch Wiki -- [WireGuard][arch-wiki]
- systemd-networkd -- [Netdev docs][netdev-docs]
- OPNsense -- [Road Warrior setup][opnsense-roadwarrior]

<!-- Links -->

[opnsense-roadwarrior]: https://docs.opnsense.org/manual/how-tos/wireguard-client.html
[elouworld]: https://elou.world/en/tutorial/wireguard
[arch-wiki]: https://wiki.archlinux.org/title/WireGuard
[netdev-docs]: https://www.freedesktop.org/software/systemd/man/systemd.netdev.html#%5BWireGuard%5D%20Section%20Options
