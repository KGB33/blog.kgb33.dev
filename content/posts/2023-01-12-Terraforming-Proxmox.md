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

- [Goal](#goal)
- [Other Tools Considered](#other-tools-considered)
  - [Cloud-init](#cloud-init)
  - [HashiCorp Packer](#hashicorp-packer)
  - [Ansible](#ansible)
  - [iPXE (and netboot.xyz)](#ipxe-and-netbootxyz)
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

# Goal

# Other Tools Considered

## Cloud-init

## HashiCorp Packer

## Ansible

## iPXE (and netboot.xyz)

# Pre-Terraforming Work

## Setting Up Storage

## Creating the "Template"


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
