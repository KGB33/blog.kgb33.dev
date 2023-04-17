---
title: "Gitting There on Argos"
date: 2023-04-10T12:00:00-08:00
tags: ["ArgoCD", "k8s", "GitOps"]

draft: false
---

> Once more they lifted sails, and once more they took the Argo into the open
> sea. - Jason and Medea

<!--more-->

This is part two of a series detailing my homelab Kubernetes setup.
The other parts can be found as follows:

  - Part 1: [Talosian Terraforming](/posts/2023-04-03-talosian-terriforming/)
  - Part 2: Gitting There on Argos (this part)
  - Part 3: [Playing in Traefik](/posts/2023-04-17-playing-in-traefik/)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Introduction](#introduction)
- [Installation](#installation)
  - [Ansible Role](#ansible-role)
  - [ArgoCD post install steps](#argocd-post-install-steps)
  - [Apps-of-Apps](#apps-of-apps)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Introduction

ArgoCD defines itself as a "declarative, GitOps continuous delivery tool for Kubernetes."
Basically, it allows the state of a Kubernetes cluster to be *declared* within a *git* repository,
and the actual state will be *continuously* be reconciled with the desired state (at some git ref).

I chose ArgoCD over FluxCD, a very similar project, because I used Flux at a previous internship.

# Installation

## Ansible Role

To install Argo on the cluster have an ArgoCD Ansible role. It is a simple two
tasks, create the namespace, then apply the installation yaml.

```yaml
# https://argo-cd.readthedocs.io/en/stable/getting_started/
---
- name: Create 'argocd' Namespace.
  kubernetes.core.k8s:
    name: argocd
    kind: Namespace
    state: present

- name: Apply Argo CD Install Yaml.
  kubernetes.core.k8s:
    namespace: argocd
    src: https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    apply: true
```

## ArgoCD post install steps

To use the `argocd` cli or web UI you need to login. Retrieve the default
password using either of the following commands.

<pre
  class="command-line language-bash"
  data-prompt="> "
  data-output="4-5, 7-10"
>
  <code>
kubectl get secrets -n argocd \
  argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 --decode
123abc456def789g

argocd admin initial-password -n argocd

123abc456def789g

This password must be only used for first time login. We strongly recommend you
update the password using `argocd account update-password`.
  </code>
</pre>

Then login using `argocd login localhost:8080` with the username 'admin'.

> Note: The argoCD server needs to be accessible outside of the cluster
> in order for the cli to login. Port forwarding is the easyest way to acchive this.
> `kubectl port-forward -n argocd services/argocd-server 8080:80`

Make sure to change the password and remove the initial secret!

```
argocd account update-password
kubectl delete secret -n argocd argocd-initial-admin-secret
```

## Apps-of-Apps

A common method to bootstrap a cluster is the "app of apps" pattern. Offical
documentation for this pattern can be found
[here](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/).
Basically, there is one meta app that configures the definitions of all other
apps.

Given the following file tree ([on Github](https://github.com/KGB33/homelab/tree/0414b20a3b33c1a16c172a59b8e1899a66c38b46/k8s-apps)).


```
 homelab/k8s-apps/
├──  argo-sources/
│  ├──  blog-kgb33-dev.yaml
│  ├──  metalLB.yaml
│  ├──  sealed-secrets.yaml
│  └──  traefik.yaml
├──  blog-kgb33-dev/
│  └──  ...
├──  metalLB/
│  └──  ...
├──  sealed-secrets/
│  └──  ...
├──  traefik/
│  └──  ...
├──  meta.yaml
└──  README.md
```

I have a file called `meta.yaml` that declares the `argo-sources` directory as
an Argo app. Each file within that directory declares the neighboring directory
as an Argo app.


```yaml
# meta.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd-meta
  namespace: argocd
spec:
  destination:
    namespace: argocd
    server: 'https://kubernetes.default.svc'
  source:
    path: k8s-apps/argo-sources
    repoURL: 'https://github.com/KGB33/homelab.git'
    targetRevision: HEAD
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Apply the `meta.yaml` file: `kubectl apply -f meta.yaml`. Then
sync it using `argocd app sync argocd-meta`.

![AgoCD tree view of the meta app.](/images/posts/2023-04-k8s/argo-apps-of-apps.png)

Now that each app definition has been synced, the apps themselves can be
synced. All of my apps are in the 'default' project, so I can sync that instead
of each individual app: `argocd app sync --project default`.
