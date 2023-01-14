---
title: "Terraforming Proxmox"
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
  - [Resource Definition](#resource-definition)
  - [Variable Variables](#variable-variables)
    - [Sops Aside](#sops-aside)
  - [Network Configuration](#network-configuration)
- [Provisioners](#provisioners)
    - [Connection](#connection)
    - [File](#file)
    - [Ansible](#ansible-1)
    - [Final Scripts](#final-scripts)
- [Conclusion](#conclusion)

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

The meat and potatoes happens here. There are
a few import parts. To start run `terraform init`
in the directory your Terraform code will be in.

## Defining Providers

Next, you have to define what providers Terraform
should use. You can think of providers kinda as plugins.

Create a file called `provider.tf` containg the following.

```hcl
terraform {
  required_version = "v1.3.7"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.11"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://10.0.0.101:8006/api2/json"
  pm_timeout = 10000
}
```
The `terraform` block defines what version of the Terraform CLI
to use, i.e. the output from `terraform version`. It also defines
the required providers, these can be found at the
[Terraform Registry](https://registry.terraform.io/).


The `provider "proxmox"` block lets you set configuration options.
Documentation for these options is located on the provider page at the
previous link.

## Resource Definition

The proxmox provider defines two resources, one to manage VMs
and another to manage LXC Containers. The general format to define
resources is as follows:

```hcl
resource "resource_type" "resource_name" {
    # Content ...
}
```

So my (super) truncated resource definition is below.


```hcl
resource "proxmox_vm_qemu" "k8s-VMs" {
  for_each = {
    # Glint
    gnar = {
      ip      = "10.0.0.112",
      macaddr = "22:d4:92:84:f1:bb",
      id      = 501,
      node    = "glint"
    }
  }
  name        = "${each.key}.kgb33.dev"
  desc        = "K8s Node #1 \n ${each.key}.kgb33.dev \n IP: ${each.value.ip}"
  target_node = each.value.node
  clone       = "ubuntu22.04-template"
  vmid        = each.value.id
}
```

## Variable Variables

In the above snippet you might have noticed the `for_each` block.
This means that for each "key" in the block another resource will
be created. When a `for_each` block is present the special `each.key`
and `each.value` variables are available.
You can use these variables as follows:

```hcl
# String Interpolation
name = "${each.key}.kgb33.dev" # "gnar.kgb33.dev"

# Using `each.value`
target_node = each.value.node # "glint"
```

You can also define variables outside of resources.
Create a new block:

```hcl
variable "variable_name" {
    type = String
    # More options ...
}
```
Then it can be used via `var.variable_name`.

### Sops Aside

There is several ways to set these variables, one of which is to
use a special `terraform.tfvars` file. This is a simple text file
in the format `variable_name = value`.

I'm using [SOPS](https://github.com/mozilla/sops) to securely store these
sensitive variables in git. I wrote a short getting starting guide
[here](/til/2023-01-08-sops-and-age/).

## Network Configuration

To be able to access the newly created VMs they need to have static IP
addresses. Thus, the `ip` and `madaddr` values in the `for_each` block
need to match the values in OPNsense.

![OPNsense Static IP](/images/posts/2023-01-12-terraforming-proxmox/OPNsense-static-ips.png)

Currently, the static IP addresses are manually configured in OPNsense, but
that could probably be automated using
[ansibleguy/collection_opnsense](https://github.com/ansibleguy/collection_opnsense).

# Provisioners

Great, now we can create VMs by cloning a template, but they
aren't very useful. In fact they all have the same host name.
Luckally Terraform can run "provisioners" on newly created
resources.

These provisioners are defined inside the resource block and
are run top-to-bottom.

### Connection

In order for provisioners to be useful they need to be able to connect.
Unsuprizingly the `connection` block defines this.

```hcl
resource "proxmox_vm_qemu" "k8s-VMs" {
  # ...
  connection {
      host  = each.value.ip
      type  = "ssh"
      user  = "kgb33"
      agent = true
  }
  # ...
```

Each option is pretty self explanatory.
However, if no valid keys are present in your `ssh-agent`
the connection will fail via timeout.

### File

The first provisioner I defined copies an Ansible playbook to the host.

```hcl
  # ...
  provisioner "file" {
    source      = "./provisioners/highstate.yaml"
    destination = "highstate.yaml"
  }
  # ...
```
### Ansible

The second provisioner runs the playbook; yes, that is all on one line.

```hcl
  # ...
  provisioner "remote-exec" {
    inline = [
      "ansible-playbook --connection=local --inventory 127.0.0.1, --limit 127.0.0.1 highstate.yaml -e 'ansible_become_password=${var.become_password}' --extra-vars 'host=${each.key}'",
    ]
  }
  # ...

```
An better way of running the previous two provisioners would be using
`local-exec` (instead of `file` and `remote-exec`). You would create a
`null_resource` that dependens on the "k8s-VMs" resource defined. Then the null
resource has a `local-exec` provisioner that runs the ansible playbook.
But that sounds a project for later.

### Final Scripts

Lastly, I have a provisioner that outputs some basic information about the
host.

```hcl
  # ...
  provisioner "remote-exec" {
    inline = [
      "hostname -f",
      "ip addr"
    ]
  }
}
```

This is in a different provisioner block from the latter because
`var.become_password` is marked as sensitive, so all the output
is redacted.


# Conclusion



<!-- link -->
[ansible-proxmox]: https://docs.ansible.com/ansible/latest/collections/community/general/proxmox_module.html
[proxmox-ceph]: https://pve.proxmox.com/wiki/Deploy_Hyper-Converged_Ceph_Cluster
