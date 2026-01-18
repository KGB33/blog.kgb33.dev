---
title: "Nix Tricks"
pubDate: "2025-02-05"
tags: ["nixos", "nix", "homelab", "proxmox"]

draft: false
---


Nix is the best configuration management tool. Declarative, programmable,
version controlled machine configs, what more could you want?

<!--more-->

Clustering and high availability, but we've got Kubernetes for that!


---

I've got a ton of super cool NixOS and home-lab stuff to write about, but there
is a huge amount of background knowledge required to understand first. This post
acts as a highlight of neat or complex parts of the configuration.

# Table of Contents
<!--toc:start-->
- [Why NixOS](#why-nixos)
- [Building NixOS ISOs](#building-nixos-isos)
- [Referencing other configuration options](#referencing-other-configuration-options)
- [Let-In Expressions](#let-in-expressions)
- [Sharing Variables across Hosts](#sharing-variables-across-hosts)
<!--toc:end-->



# Why NixOS

I've been running a three to four node Proxmox cluster for the last four years;
and it has worked amazingly the entire time. I've also been daily driving NixOS
for about two years now, and I've been extremely impressed with several of
Nix/NixOS features. First, Nix's multi-machine capacities; especially recently
when I refactored my Home-Manager config to work on Linux and Darwin. Second, I
prefer declarative GitOps based configuration methods. I've found that tools
like ArgoCD and NixOS have a better developer experience then their imperative
counterparts - after the initial learning curve anyways. Third, I wanted to try
something new, it's a home-lab, not a home-enterprise.

# Building NixOS ISOs

This might come as a surprise to some, but the first step in installing an
operating system is to install it. NixOS provides a simple way to build an ISO
(which is named after it's ISO-9660 standard).

To build an ISO, just add some modules from nixpkgs to your system's
definition. The modules I used are
[here](https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/installer/cd-dvd),
but there are more options (like netboot) in neighboring folders.

```nix
{
  description = "NixOS machine configs.";

  inputs = {
    nixpkgs = {url = "github:NixOS/nixpkgs/nixos-unstable-small";};
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      iso = lib.nixosSystem {
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-plasma5.nix"
          "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
          ./hosts/iso/configuration.nix
        ];
        specialArgs = {inherit inputs outputs;};
      };
    };
  };
}
```
# Referencing other configuration options

Say you have a service that puts a file somewhere on disk:

```nix
{...}: 
{
sops = {
  secrets = {
   "DISCORD_TOKEN" = {
    sopsFile = ./roboShpeeSecrets.env;
    format = "dotenv";
    restartUnits = ["docker-roboShpee.service"];
  };
}
```

You could read the documentation (aka source code) to find the default path, or you could reference the sops config.

```nix
{...}: 
{
  virtualisation.oci-containers.containers = {
    roboShpee = {
      image = "ghcr.io/kgb33/roboshpee:latest";
      pull = "always";
      environmentFiles = [
        # This line here
        config.sops.secrets.DISCORD_TOKEN.path
      ];
    };
  };
}
```

# Let-In Expressions

I have Caddy setup as a reverse proxy for some of my services. The actual
config for each host is almost identical, just the port changes. I can use a
let-in block to define a function that takes a port number and templates out a
reverse proxy. 

Note that the above reuse tip is being used again here.

```nix
{...}: {
  services.caddy = {
    environmentFile = config.sops.secrets.cloudflare_dns.path;
    virtualHosts = let
      reverseProxy = port: ''
        reverse_proxy localhost:${toString port}

        tls {
          dns cloudflare {
            api_token {env.CF_API_TOKEN}
          }
        }
      '';
    in {
      "blog.kgb33.dev" = {
        extraConfig = reverseProxy 1313; # <- Calling the teplate function here
      };
      "${config.services.grafana.settings.server.domain}" = {
        # And Here!
        extraConfig = reverseProxy config.services.grafana.settings.server.http_port;
      };
    };
  };
}
```

# Sharing Variables across Hosts

Unfortunately, the variables accessible via `config.services` are per-host, so I can't set up Caddy on one machine,
and use the host/port variables from another. 

What I can do is define a dummy module that only provides variables to share across hosts. 
The `shared` module below is used in a few spots to allow cross-machine communication.


```nix
{
  lib,
  options,
  ...
}:
with lib; {
  options.shared = mkOption {
    type = types.attrs;
    readOnly = true;
    default = rec {
      monitoring = {
        loki = {
          hostName = "ophiuchus";
          httpPort = 3030;
          grpcPort = 9096;
        };
        mimir = {
          hostName = "ophiuchus";
          httpPort = 9009;
        };
      };

      hosts = {
        ophiuchus = {
          hostId = "e7ea22a6"; # `head -c4 /dev/urandom | od -A none -t x4`
          ipv4 = "10.0.9.104";
          ipv4Mask = "24";
        };
      };

      hostMappings =
        mapAttrs' (
          host: values: {
            name = values.ipv4;
            value = ["${host}" "${host}.kgb33.dev"];
          }
        )
        hosts;
    };
  };
}
```

It's used in the network section to define hosts (the '`//`' operator combines
two attribute sets).

```nix
{...}: {
  networking = {
    hosts =
      {
        "174.31.116.214" = [ "traefik.k8s.kgb33.dev" ];
      }
      // config.shared.hostMappings;
  };
}
```

Or here, where it is used to define where the Prometheus agent on each host writes data.

```nix
{config, ...}: {
  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "10s";
    remoteWrite = [
      {
        url = with config.shared.monitoring.mimir; "http://${hostName}:${toString httpPort}/api/v1/push";
        name = "mimir";
      }
    ];
  };
}
```


