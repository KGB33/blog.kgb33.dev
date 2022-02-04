---
title: "Ansible for Localhost"
date: 2022-02-03T09:30:36-08:00
tags: ["ansible", "arch-linux"]

draft: true
---
Ansible is a super powerful system configuration tool that is normally
used to manage sets of servers. However, as you might have derived from
the title it can also be used to configure a local deployment.

<!--more-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [End Goal](#end-goal)
- [Basics](#basics)
    - [Project Structure](#project-structure)
- [Installing Packages](#installing-packages)
    - [Variable Files](#variable-files)
    - [Updating `pacman.conf` to Enable Parallel Downloads](#updating-pacmanconf-to-enable-parallel-downloads)
- [Specialized package managers](#specialized-package-managers)
  - [Install `paru`](#install-paru)
  - [Use `paru` to install packages.](#use-paru-to-install-packages)
  - [`pipx`](#pipx)
- [Create user](#create-user)
  - [Add to sudoers](#add-to-sudoers)
  - [Add to docker group](#add-to-docker-group)
  - [Pull down dotfiles](#pull-down-dotfiles)
- [Install Applications From Source](#install-applications-from-source)
  - [java-debug & vscode-java-test example](#java-debug--vscode-java-test-example)
- [Systemd Units](#systemd-units)
  - [System level](#system-level)
  - [User level](#user-level)
- [Pacman hooks](#pacman-hooks)
  - [jdtls copy](#jdtls-copy)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# End Goal
Configure a brand new installation of Arch Linux such that
one (ansible) command can install and configure the system.

During installation the following dependencies must be manually installed.
Either during the `pacstrap` step or with `pacman` when chrooted in.
```console
base-devel ansible git
```
After the system has restarted and the user is logged into
a tty as root, run the following command:
```console
ansible-pull -U https://git.kgb33.dev/kgb33/ansible.git -e "passwd=********"
```

# Basics

Ansible has a command `ansible-pull` that can pull down
and run playbooks defined within a remote git repository.

The repository should have the following structure.


### Project Structure
```
 ./
├──  vars/
│  └──  installed-packages
├──  ansible.cfg
├──  inventory.yml
├──  local.yml
└──  README.md
```

This project has three main files.
  - `local.yml` - The main playbook.
  - `ansible.cfg` - Optional, Used to configure ansible.
  - `inventory.yml` - Optional, suppresses no inventory file warnings.

> Note: While both `yml` and `yaml` are valid yaml file extensions,
> ansible will only detect files ending with `.yml`.


# Installing Packages
Ansible already knows how to install packages from the
standard distribution's package managers (`apt`, `dnf`, `pacman`, etc.).
Installing AUR packages with `paru` requires a custom plugin.

To use the distribution package manager create a task as follows.

```yaml
- hosts: localhost
  tasks:
    - name: Install tmux
      become: yes
      package:
        name: tmux
        state: present
```

This is fairly tedious to write out a task for each package.
[variables][ansible-variables] can be used instead.

```yaml
- hosts: localhost
  tasks:
    - name: Install Packages
      become: yes
      package:
        name: "{{item}}"
        state: present
      with_items:
        - htop
        - tmux
        - git
```

Here the `name: "{{item}}"` acts kinda like a for-each loop.
The task will run for each item in `with_items`.

### Variable Files
I have a lot of packages installed, 87 to be exact,
I don't want to have to type out a line for each one.
Variables and Variable files can help us with this.
Furthermore, these files can be auto-generated with
some terminal magic.

Variable files are `.yml` files and lists of variables are
defined using yaml lists.

```yaml
pacman_packages:
  - alacritty
  - ansible
  - autoconf
  ...
```

The following script creates `vars/pacman_packages.yml` and `vars/aur_packages.yml`.
These files contain the currently installed packages on the system from the
Arch Linux repositories and from the AUR respectively.
```bash
#!/bin/sh
[ -d vars ] || mkdir vars # Create dir if it does not exist

# Generate AUR package list
pacman -Qqm \
        | awk 'BEGIN{print "aur_packages:"}; {printf"  - %s\n", $1};' \
        > vars/aur_packages.yml

# Generate pacman package list
pacman -Qqe \
        | grep -v "$(pacman -Qqm)" \
        | awk 'BEGIN{print "pacman_packages:"}; {printf"  - %s\n", $1};' \
        > vars/pacman_packages.yml
```

Then to use these files in the Install Packages tasks change the yaml to the following.
```yaml
- hosts: localhost
  vars_files:
    - vars/pacman_packages.yml
    - vars/aur_packages.yml
  tasks:
    - name: Install Packages
      become: yes
      package:
        name: "{{pacman_packages}}"
        state: present
```

> Note: Here we are passing the list of packages to pacman, rather
> than one at a time.
> This speeds up the task because it uses only one call to pacman,
> which limits the pre/post installation tasks, as well as allowing
> us to take advantage of parallel downloads.

### Updating `pacman.conf` to Enable Parallel Downloads

By default parallel downloads is disabled in `/etc/pacman.conf`.
To enable it (and change some other settings) create a new
task **before** the "Install Packages" task. Furthermore,
running `reflector` might be a good idea before downloading
hundreds of packages.

```yaml
  tasks:
    - name: Update pacman.conf Settings
      lineinfile:
        path: /etc/pacman.conf
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
      loop:
        - { regexp: '^#Color', line: 'Color' }
        - { regexp: '^#VerbosePkgLists', line: 'VerbosePkgLists' }
        - { regexp: '^#ParallelDownloads', line: 'ParallelDownloads = 7' }

    - name: Install Reflector
      become: yes
      pacman:
        name: reflector
        state: present

    - name: Update Reflector Settings
      lineinfile:
        path: /etc/xdg/reflector/reflector.conf
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
      loop:
        - { regexp: '^# --country France,Germany', line: '--country US,CA ' }
        - { regexp: '^--latest', line: '--latest 50' }

    - name: Enable Reflector.timer
      systemd:
        name: reflector.timer
        state: started
        enabled: yes

    - name: Install Packages
 	...
```

# Specialized package managers
Unfortunately `pacman` cannot install AUR packages,
an AUR helper is needed for that. My preferred AUR helper is
`paru`, but any helper should work.

`makepkg` cannot be run as root, In fact, the Arch Linux
[wiki][arch-wiki-ansible] recommends creating a user that
can run pacman without a password.

Create two new tasks as follows:
```yaml
 tasks:
    ...
    - name: Create AUR-Builder User
	user: name=aur_builder
    - name: Give aur_builder Pacman privileges
	lineinfile:
        path: /etc/sudoers.d/aur_builder-allow-to-sudo-pacman
		state: present
        line: "aur_builder ALL=(ALL) NOPASSWD: /usr/bin/pacman"
		validate: /usr/sbin/visudo -cf %s
        create: yes
```

The first task creates a new user, `aur_builder`,
then the second allows it to run pacman without a
password. Additionally, because `aur_builder`  does not have
a password, only root can `su` into it.

## Install `paru`

Paru is installed using a series of shell commands.
Furthermore, because Paru is written in rust, and rust takes
a while to compile, the task checks to see if the binary is
present at `/usr/bin/paru` before running.

```yaml
tasks:
    ...
    - name: Install paru
	become: yes
    become_user: aur_builder
	args:
        creates: /usr/bin/paru
	shell: |
		git clone https://aur.archlinux.org/paru.git
		cd paru
        yes | makepkg -si
		cd -
        rm -rf paru
```

## Use `paru` to install packages.
The Ansible [pacman plugin][ansible-pacman] allows the executable to be overridden.
This allows all the logic built into `community.general.pacman` to
extend to `paru`.

```yaml
  tasks:
    ...
    - name: Install AUR Packages
      become: yes
      become_user: aur_builder
      pacman:
        name: "{{aur_packages}}"
        state: present
        executable: paru
```
## `pipx`
I have several python applications installed. Rather than
allow pacman to manage different python libraries, `pipx` installs
each application in its own separate virtual environment.

Ansible has a plugin [`community.general.pipx`][ansible-pipx] to
manage `pipx`. As a result, the task will closely mirror the pacman
and paru tasks.

Update `package-list.sh` to create a variable file for `pipx` too.
```bash
# Generate pipx package list
pipx list \
        | grep "package" \
        | awk 'BEGIN{print "pipx_packages:"}; {printf"  - %s\n", $2};' \
        > vars/pipx_packages.yml
```
Then update the `vars_files` and add a new task.

```yaml
- hosts: localhost
  vars_files:
    - vars/pacman_packages.yml
    - vars/aur_packages.yml
    - vars/pipx_packages.yml
  tasks:
    ...
    - name: Install pipx Packages
      community.general.pipx:
        name: "{{ item }}"
      with_items:
        - "{{ pipx_packages }}"
```

> `pipx` can only install one item at a time, hence the for-each
> style `with_items` syntax.


# Create user
## Add to sudoers
## Add to docker group
## Pull down dotfiles

# Install Applications From Source
## java-debug & vscode-java-test example

# Systemd Units
## System level
## User level
  - `spotifyd`
  - `pipxUpdate` (timer & service)

# Pacman hooks
## jdtls copy




<!-- Links -->
[arch-wiki-ansible]: https://wiki.archlinux.org/title/Ansible#Package_management

[ansible-pacman]: https://docs.ansible.com/ansible/latest/collections/community/general/pacman_module.html
