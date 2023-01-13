---
title: "2023-01-12-Terraforming-Proxmox"
date: 2023-01-12T12:00:00-08:00
tags: ["terraform", "proxmox", "ansible"]

draft: true
---

I recently experimented automating VM creation across my
Proxmox cluster. I tested out several tools before finally
settling on Terraform & cloning from a Proxmox "template".

<!--more-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Goals](#goals)
  - [Non-Goals](#non-goals)
- [Other Tools Considered](#other-tools-considered)
  - [Ansible](#ansible)
  - [Cloud-init](#cloud-init)
  - [iPXE (and netboot.xyz)](#ipxe-and-netbootxyz)
  - [HashiCorp Packer](#hashicorp-packer)
- [Pre-Terraforming Work](#pre-terraforming-work)
  - [Setting Up Storage](#setting-up-storage)
  - [Creating the "Template"](#creating-the-template)
- [Terraforming Proxmox](#terraforming-proxmox)
  - [Defining Providers](#defining-providers)
  - [Variable Variables](#variable-variables)
    - [Sops Aside](#sops-aside)
  - [Network Configuration](#network-configuration)
    - [OPNsense Static IPs](#opnsense-static-ips)
  - [Provisioners](#provisioners)
    - [File](#file)
    - [Ansible](#ansible-1)
    - [Final Scripts](#final-scripts)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Goals

Use Infrastructure-as-code tools to create multiple VMs on various
Proxmox nodes. Eventually, these VMs will run a Kubernetes cluster.

 - VMs are created (and destroyed) using a single command.
 - Minimize manual steps.

## Non-Goals

There really is only one non-goal - Persistent Storage.
None of the (planned) Kubernetes services need persistent
storage, so that will be a project for another day.

# Other Tools Considered

I had a pretty good idea that I would end up using Terraform,
but I also tried out a bunch of other tools too.

## Ansible

My original plan was to use the [Proxmox module][ansible-proxmox]
and keep everything in Ansible. This would have worked, but I ran into a few
issues. The configuration was obtuse, I could only clone templates (no iso/iPXE)

## Cloud-init

The next three all deal with the creation/configuration
of the base image. Of these three cloud-init was my favorite. Unfortunately
I was unable to get it to work in Proxmox even though it worked on a local `qemu`
VM. I even went so far as to create a TFTP server [raincloud](https://github.com/KGB33/raincloud).

## iPXE (and netboot.xyz)

These were also super cool. I ended up setting `boot.netboot.xyz` to the default
netboot url. Eventually I could (and probably will) use cloud-init and iPXE to
automate the [Creating the "Template"](#creating-the-template) step.

## HashiCorp Packer

Packer would be an amazing tool *if* I needed to build a custom iso, but
I don't. I also think that learning the previous two tools will be a better
use of my time. I honestly don't think I will ever have a reason to use packer
in my homelab.

# Pre-Terraforming Work

As alluded to previously, there are a few steps that
still need to be done manually. Namely setting up the VM
to clone.

## Setting Up Storage

My Proxmox cluster is pretty bare bones, so there is (was)
no network storage. Unfortunately, when cloning a VM the new
VM must have the same storage, i.e. a template on Host A local storage
cannot be cloned to Host B.

My solution for this was to create a Ceph storage pool. I created
it following [Deploy Hyper-Converged Ceph Cluster][proxmox-ceph],
although I only have one Object Storage Daemons (OSD) so I had to
manually lower the min placement groups to one.


## Creating the "Template"

Creating the template is super easy. Just follow the Ubuntu server
install, just make sure to import your ssh keys! Once the installation
is complete, remove the CD-ROM disk & reboot. When the server comes
back up install Ansible. Shut the machine back down then it's good to go.

> Note: You don't need to convert the VM to a template. In fact if you
> don't it's easier to make changes to the base image.

# Terraforming Proxmox

## Defining Providers

## Variable Variables
### Sops Aside

## Network Configuration
### OPNsense Static IPs

## Provisioners

### File
### Ansible
### Final Scripts

<!-- link -->
[ansible-proxmox]: https://docs.ansible.com/ansible/latest/collections/community/general/proxmox_module.html
[proxmox-ceph]: https://pve.proxmox.com/wiki/Deploy_Hyper-Converged_Ceph_Cluster
