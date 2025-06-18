---
title: "Talosian Terraforming"
pubDate: "2023-04-03"
tags: ["terraform", "proxmox", "talos", "k8s", "cilium"]

draft: false
---

> Thrice a day would Talos stride around the island; his brazen feet were
> tireless. - The Story of Perseus

<!--more-->

This is part 1 of a series detailing my homelab Kubernetes setup.
The other parts can be found as follows:

  - Part 1: Talosian Terraforming (this part)
  - Part 2: [Gitting There on Argos](/posts/2023-04-10-gitting-there-on-argos/)
  - Part 3: [Playing in Traefik](/posts/2023-04-17-playing-in-traefik/)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
  - [Static IPs](#static-ips)
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

> Note: A few months ago I wrote about using [Terraform to provision Ubuntu
> 22.04 VMs](/posts/2023-01-12-terraforming-proxmox/). Using Talos instead
> allows the re-creation of the environment to be much faster and repeatable.
> For example, creating the six u22.04 VMs took about 30 mins, it takes just
> under one minute to create the talos VMs.


# Prerequisites

In order for the Terraform to create a VM using an ISO, each node within the
Proxmox cluster needs access to the ISO file. Ideally this would be done using a
shared storage solution like ceph. Instead, I manually downloaded the
`talos-amd64.iso` images to the same (as in name) location on each host.
Furthermore, these can be different talos versions, in a later step talos will
automatically upgrade itself to the latest version.

![`talos-amd64.iso` in the local iso storage on Targe](../../static/images/posts/2023-04-k8s/talos-iso-on-targe.png)

On the other hand, the only local dependencies are the `terraform` and
`talosctl` command line tools.

## Static IPs

The fresh, pre-configuration talos VM has a handy dashboard that displays
system information, including the IP address. However, for consistency, I
set a static DHCP lease for each node.


<pre
  class="command-line language-bash"
  data-user="kgb33"
  data-host="vyos [edit] "
  data-output="2-14"
>
  <code>
show service dhcp-server shared-network-name HOMELAB
 subnet 10.0.0.0/24 {
     default-router 10.0.0.1
     lease 86400
     name-server 10.0.3.53
     range 0 {
         start 10.0.0.5
         stop 10.0.0.99
     }
     static-mapping teemo {
         ip-address 10.0.0.116
         mac-address 22:d4:92:84:f1:ff
     }
 }
  </code>
</pre>

# Throwing Rocks (`terraform apply`)

Terraform is only responsible for creating the VM from the iso,
it does no provisioning. As such, the main terraform file is fairly simple.

```hcl
resource "proxmox_vm_qemu" "k8s-VMs" {
  for_each = {
   # Targe
   teemo = {
      ip      = "10.0.0.116",
      macaddr = "22:d4:92:84:f1:ff",
      id      = 505,
      node    = "targe"
    },
   # More nodes...
  }

  name        = "${each.key}.kgb33.dev"
  desc        = "K8s Node #1 \n ${each.key}.kgb33.dev \n IP: ${each.value.ip}"
  target_node = each.value.node
  iso         = "local:iso/talos-amd64.iso"
  vmid        = each.value.id
  memory      = 4096
  sockets     = 2
  scsihw      = "virtio-scsi-single"
  onboot      = true

  network {
    model   = "virtio"
    bridge  = "vmbr0"
    macaddr = each.value.macaddr
  }

  disk {
    type     = "scsi"
    storage  = "cPool01"
    size     = "8G"
    iothread = 1
  }

  timeouts {
    create = "10m"
  }
}
```

It first defines some basic information about the VM: hostname, iso, if it should
start at boot etc. Then it defines the network device to ensure it gets the
correct MAC so the DHCP reservations work and defines a 8GB disk.

> Note: Talos needs a `x86-64-v2` compatable CPU, the (terraform) default CPU
> is 'host', which works for my machines, but might not work on others. See the
> [Talos Proxmox install
> guide](ttps://www.talos.dev/v1.3/talos-guides/install/virtualized-platforms/proxmox/)
> for more info.

# Talos

The Talos installation is only four steps:
  1. Generate Configuration
  2. Configure Control Plane(s)
  3. Configure Worker Nodes
  4. Bootstrap ectd

## Configuration

Run the following command to generate the configuration files; note that the
default cni and proxy are disabled, Cilium will be used instead.

```
talosctl gen config \
    home https://10.0.0.116:6443 \
    --config-patch '[{"op": "add", "path": "/cluster/proxy", "value": {"disabled": true}}, {"op":"add", "path": "/cluster/network/cni", "value": {"name": "none"}}]'

talosctl --talosconfig talosconfig config endpoint 10.0.0.116
talosctl --talosconfig talosconfig config node 10.0.0.116
```

The first command creates three files: `talosconfig`, `controlplane.yaml`, and `worker.yaml`. Then the second and third commands
set values within that `talosconfig`. Lastly, and optionally, create paches for each node to set the hostname.

```yaml
# paches/HOSTNAME.kgb33.dev.patch
machine:
  network:
    hostname: HOSTNAME.kgb33.dev
```

## Control Plane

Next, apply the `controlplane.yaml` to the control plane, I used a python script, so it's easy to
remember and extend.

```python
#! /bin/python
import subprocess

nodes: dict[str, str] = {
    "teemo.kgb33.dev": "10.0.0.116",
}

for hostname, ip in nodes.items():
    subprocess.run(
        [
            "talosctl",
            "apply-config",
            "--insecure",
            "--nodes",
            ip,
            "--config-patch",
            f"@patches/{hostname}.patch",
            "--file",
            "./controlplane.yaml",
        ],
    )
```

## Worker Nodes

As you might have guessed the worker nodes are the same process, just with the `worker.yaml` instead.

```python
#! /bin/python
import subprocess

nodes: dict[str, str] = {
    "twitch.kgb33.dev": "10.0.0.117",
    "gnar.kgb33.dev": "10.0.0.112",
    "gwen.kgb33.dev": "10.0.0.113",
}

for hostname, ip in nodes.items():
    subprocess.run(
        [
            "talosctl",
            "apply-config",
            "--insecure",
            "--nodes",
            ip,
            "--config-patch",
            f"@patches/{hostname}.patch",
            "--file",
            "./worker.yaml",
        ],
    )
```

## Bootstrap

Lastly, once all the above nodes have installed and rebooted, run the following
command to bootstrap etcd.

```
talosctl --talosconfig talosconfig bootstrap
```

Then grab the kubeconfig to allow `kubectl` access to the cluster.

```
talosctl --talosconfig talosconfig kubeconfig
```
> Note: If there is a config a `~/.kube/config` then the
> above command will prompt to merge/replace the two.
> If there is not a config there then the command will create
> a new file in the working directory called `kubeconfig`.

# Cilium

The cluster isn't quite ready yet though. Because the default proxy and cni
included with Talos was disabled it needs to be replaced. In this case with
cilium.

## Helm Template

Run the following commands to add the cilium repo and configure the helm installation and save it as `cilium.yaml`

```bash
helm repo add cilium https://helm.cilium.io/
helm template cilium cilium/cilium \
    --version 1.13.1 --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost="10.0.0.116" \
    --set k8sServicePort="6443" \
    --set=securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set=securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set=cgroup.autoMount.enabled=false \
    --set=cgroup.hostRoot=/sys/fs/cgroup \
    --set hubble.listenAddress=":4244" \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true > cilium.yaml
```

Make sure to change `k8sService{Host/Port}` to the values matching your control plane.

## Kubectl Apply

To apply run `kubectl apply -f cilium.yaml`. Then run `cilium status --wait` to view the status of the cilium install.
This will timeout before the installation is complete (at least on my low spec VMs), just re-run the command.

<pre
  class="command-line language-bash"
  data-prompt="> "
  data-output="2-22"
>
  <code>
cilium status
    /¯¯\
 /¯¯\__/¯¯\    Cilium:          OK
 \__/¯¯\__/    Operator:        OK
 /¯¯\__/¯¯\    Hubble Relay:    OK
 \__/¯¯\__/    ClusterMesh:     disabled
    \__/

Deployment        cilium-operator    Desired: 2, Ready: 2/2, Available: 2/2
Deployment        hubble-ui          Desired: 1, Ready: 1/1, Available: 1/1
DaemonSet         cilium             Desired: 4, Ready: 4/4, Available: 4/4
Deployment        hubble-relay       Desired: 1, Ready: 1/1, Available: 1/1
Containers:       cilium             Running: 4
                  cilium-operator    Running: 2
                  hubble-ui          Running: 1
                  hubble-relay       Running: 1
Cluster Pods:     15/15 managed by Cilium
Image versions    cilium             quay.io/cilium/cilium:v1.13.1@sha256:428a09552707cc90228b7ff48c6e7a33dc0a97fe1dd93311ca672834be25beda: 4
                  cilium-operator    quay.io/cilium/operator-generic:v1.13.1@sha256:f47ba86042e11b11b1a1e3c8c34768a171c6d8316a3856253f4ad4a92615d555: 2
                  hubble-ui          quay.io/cilium/hubble-ui:v0.10.0@sha256:118ad2fcfd07fabcae4dde35ec88d33564c9ca7abe520aa45b1eb13ba36c6e0a: 1
                  hubble-ui          quay.io/cilium/hubble-ui-backend:v0.10.0@sha256:cc5e2730b3be6f117b22176e25875f2308834ced7c3aa34fb598aa87a2c0a6a4: 1
                  hubble-relay       quay.io/cilium/hubble-relay:v1.13.1@sha256:ad7ce650c7877f8d769264e20bf5b9020ea778a9530cfae9d67a5c9d942c04cb: 1
  </code>
</pre>
