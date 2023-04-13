---
title: "Playing in Traefik"
date: 2023-04-13T12:00:00-08:00
tags: ["traefik", "k8s"]

draft: false
---

> Go play in traffic - Parents everywhere

<!--more-->

This is part three of a series detailing my homelab Kubernetes setup.
The other parts can be found as follows:


  - Part 1: [Talosian Terraforming](/posts/2023-04-03-talosian-terriforming/)
  - Part 2: [Gitting There on Argos](/posts/2023-04-10-gitting-there-on-argos/)
  - Part 3: Playing in Traefik (this part)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Introduction](#introduction)
- [MetalLB Precursor](#metallb-precursor)
  - [Interface Configuration](#interface-configuration)
- [Traefik](#traefik)
  - [Traefik Configuration](#traefik-configuration)
  - [Blog Ingress](#blog-ingress)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Introduction

Using the ArgoCD setup described last time I got this blog running on the
cluster, but I still can't access it from outside. Using Traefik, along with some
other tools, I can accomplish this.

# MetalLB Precursor

The first of these tools is MetalLB. MetalLB is designed to provide a **L**oad **B**alancer
to bare **metal** clusters - something cloud managed clusters get 'for free'.

Like everything else in the cluster metalLB is installed using ArgoCD. Argo
syncs a copy of the [recommened kustomize
file](https://metallb.universe.tf/installation/#installation-with-kustomize)
and two other files: one defining an IP-pool, and another defining the
advertisement for that pool. Both of these definitions are below.

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.8.0/24
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: layer2-advertisment
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
```

First, an new pool of ip addresses, named default-pool, is defined from the `10.0.8.0/24` subnet.
Then, metalLB is configured to respond to ARP (i.e layer 2) requests for that subnet.

Interestingly, metalLB doesn't need a dedicated interface, it listens
on all of them. In the following image, MetalLB is telling my router
(`10.0.8.1`) that `10.0.8.138` (the blog) is at `22:d4:92:84:f1:11`. Which,
from the terraform definition, we know is the `twitch` node.

![10.0.8.138 ARP Response](/images/posts/2023-04-k8s/metallb-arp.png)

Furthermore, the arp table on my router has both entries.

<pre
  class="command-line"
  data-prompt="kgb33@vyos:~$"
  data-output="2,3"
>
  <code>
kgb33@vyos:~$ arp -e | grep "f1.11"
blog.kgb33.dev           ether   22:d4:92:84:f1:11   C                     eth2
twitch.kgb33.dev         ether   22:d4:92:84:f1:11   C                     eth2
  </code>
</pre>

In this case metalLB responded on the same node that the pod was running on.
However, in some cases these will be different nodes, and the request will pass
between them using `kube-proxy` (or cilium in this case).

## Interface Configuration

To properly route traffic over different interfaces the `10.0.8.0/24`
the `10.0.8.1/24` address had to be added to the interface configuration.

```
interfaces {
    ethernet eth2 {
        address 10.0.0.1/24
        address 10.0.8.1/24
        description homelab
        hw-id 00:e2:69:4f:f3:5c
    }
}
```

# Traefik

Traefik is a reverse proxy and is replacing my old Nginx VM.
Once again the installation is manged using ArgoCD, although this time there is quite a lot more to manage.

```
❯ lt traefik
 traefik/
├──  CloudflareSecret.yaml
├──  CRD.yaml
├──  ClusterRole.yaml
├──  ServiceAccount.yaml
├──  ClusterRoleBinding.yaml
├──  Deployment.yaml
├──  DashboardService.yaml
└──  WebService.yaml
```

From top to bottom:
  - A sealed secret used for ACMEv2 DNS challengen
  - Defines the custom resources that Traefik needs to function.
  - Defining a cluster roll that allows access to stuff, including the custom resources defined later.
  - Creates the traefik service account.
  - Binds the aforementioned cluster roll to the traefik service account.
  - Basic Kubernetes deployment for the traefik pods - traefik is configured here.
  - Provides external access to the traefik dashboard.
  - Provides external HTTP and HTTPS access - i.e. the reverse proxy.

## Traefik Configuration

For now Traefik is compleatly configured using container arguments on in the
deployment spec. Note that only the `spec.spec.containers` portion of the
definition is below.

```yaml
# spec.spec.containers:
- name: traefik
  image: traefik:v2.9
  args:
    - --providers.kubernetesingress
    - --providers.kubernetescrd
    # Redirect all traffic to TLS
    - --entrypoints.web.address=:80
    - --entrypoints.web.http.redirections.entrypoint.to=websecure
    - --entrypoints.web.http.redirections.entrypoint.scheme=https
    - --entrypoints.websecure.address=:443
    # ACME Configuration
    - --certificatesresolvers.letsencrypt.acme.dnschallenge=true
    - --certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare
    - --certificatesresolvers.letsencrypt.acme.email=myemail@mail.com
    # Staging LetsEncrypt Server
    # - --certificatesresolvers.letsencrypt.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory
    - --log
    - --log.level=DEBUG
  ports:
    - name: web
      containerPort: 80
    - name: websecure
      containerPort: 443
    - name: dashboard
      containerPort: 8080
  env:
   - name: CF_DNS_API_TOKEN
     valueFrom:
       secretKeyRef:
         name: cloudflare-api-token
         key: cf-token
   - name: CF_ZONE_API_TOKEN
     valueFrom:
       secretKeyRef:
         name: cloudflare-api-token
         key: cf-token
```

Notice the `cloudflare-api-token` secret is passed to the pod as an environment
variable. This allows the ACME provider to use it and authenticate with Cloudflare.

Lastly, the `WebService` definition reserves an IP address from the metallb pool
using a annotation.

```yaml
metadata:
  annotations:
    metallb.universe.tf/loadBalancerIPs: 10.0.8.138
```

## Blog Ingress

Lastly, an `IngressRoute` needs to be defined for the blog.

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: blog-kgb33-dev-ingress
  namespace: blog-kgb33-dev
spec:
  entryPoints:
    - websecure
  routes:
  - match: Host(`blog.kgb33.dev`)
    kind: Rule
    services:
    - name: blog-kgb33-dev
      port: 1313
  tls:
    certResolver: letsencrypt
```

The IngressRoute is mostly self-explanatory (and one of Traefik's custom
resources). It can be translated to: "When traffic with a destination host
matching 'blog.kgb33.dev' is seen on the 'websecure' entrypoint proxy that
traffic to the `blog-kgb33-dev` service. Furthermore, provide a TLS certificate
using the 'letsencrypt' certResolver."
