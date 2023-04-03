---
title: "Talosian Terraforming"
date: 2023-04-03T12:00:00-08:00
tags: ["terraform", "proxmox", "talos", "k8s", "cilium"]

draft: false
---

> Thrice a day would Talos stride around the island; his brazen feet were
> tireless. - The Story of Perseus

<!--more-->

This is part 1 of a series detailing my homelab Kubernetes setup.
The other parts can be found as follows:

  - Part 1: Talosian Terraforming (this part)
  - Part 2: Gitting There on Argos
  - Part 3: Playing in Traefik

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Introduction](#introduction)
- [Terraform](#terraform)
  - [Prerequisites](#prerequisites)
  - [Throwing Rocks (`terraform apply`)](#throwing-rocks-terraform-apply)
- [Talos](#talos)
  - [Configuration](#configuration)
  - [Control Plane](#control-plane)
  - [Worker Nodes](#worker-nodes)
  - [Bootstrap](#bootstrap)
- [Cilium](#cilium)
  - [Helm Template](#helm-template)
  - [Kubectl Apply](#kubectl-apply)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Introduction

The base of every kubernetes cluster is the operating system it runs on. I
eventually chose Talos from Sidero Labs. Talos is a Linux operating system that
is build from the ground up to run Kubernetes. It advertises itself using a
bunch of buzzwords: "immutable", "secure", "minimal", blah blah blah. I chose
Talos for three reasons, it's easily configured, it's under active
development, and Sidero Labs provides ARM builds.

> Note: A few months ago I wrote about using Terraform to provision Ubuntu
> 22.04 VMs. Using Talos instead allows the re-creation of the environment to
> be much faster and repeatable. For example, creating the six u22.04 VMs took
> about 30 mins, it takes just under one minute to create the talos VMs.

# Terraform

## Prerequisites

## Throwing Rocks (`terraform apply`)

# Talos

## Configuration

## Control Plane

## Worker Nodes

## Bootstrap

# Cilium

## Helm Template

## Kubectl Apply
