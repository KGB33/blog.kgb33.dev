---
title: "GPG Keys"
date: 2022-10-28T10:01:42-07:00
tags: ['git', 'gpg']

draft: true
---

Have you ever wondered why (or how) someone's commit has a fancy *"verified"* badge on Github?

![Github Verified Commit Badge][gpg-verified-badge]

They have either created & committed from the Github web editor or signed their commit using a PKI key.

<!--more-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [PKI Overview](#pki-overview)
- [Steps to Sign](#steps-to-sign)
  - [Generating a Key](#generating-a-key)
  - [Configure GPG & Git](#configure-gpg--git)
  - [Commit!](#commit)
  - [Unverified?](#unverified)
  - [Uploading to a Key Server](#uploading-to-a-key-server)
- [Key Maintenance](#key-maintenance)
  - [Backup, Backup, Backup](#backup-backup-backup)
  - [Revocation](#revocation)
  - [Expiration](#expiration)
- [Extra Resources](#extra-resources)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# PKI Overview

Signing commits provides an extra layer of security to your code.
It provides proof that **you** wrote that code.
It's recommend by the [Cloud Native Computing Foundation][cncf-sscp].
It increases the trust others have in the security of your code.
It's also dead simple to set up.

There are three different types of keys that can be used to sign commits.
The most common option is Gnu Privacy Guard (GnuPG) Keys.
However, S/MIME, and as of Git 2.34 [changelog][git2.34-changelog],
ssh keys can also be used.

GPG Keys can also be used for a bunch of other things, including email and package signing.

> Note: "Gnu Privacy Guard" (GnuPG/gpg) is an implementation of the OpenPGP standard.
> Which originates from the freeware (but still proprietary) Pretty Good Privacy (PGP) program.
> While any OpenPGP implementation *should* work, most documentation (including this) is written with
> only GnuPG in mind.

# Steps to Sign

Before you can sign your commits you need a key, and before you can generate a key
you need to install `gnupg`. If you're on Linux it's probably all ready installed,
most distributions use gpg keys for package signing. If you are forced to used Windows it's
available as `gpg4win`, documentation & downloads can be found at [gpg4win.org](https://gpg4win.org/index.html).
For Mac, just `brew install gnupg`. I have not tested this on Windows or Mac, so if you're on those systems read at your own risk.

Optionally, setting `GNUPGHOME` prevents yet another
dot file from being created in your home directory.

```bash
export GNUPGHOME="$XDG_CONFIG_HOME/gnupg/"
```

## Generating a Key

Use one of the following commands to generate your key,
depending on the level of customization needed.
  - `--gen-key`
    - Name
	- Email
  - `full-gen-key [--expert]`
    - all `--gen-key` options
    - Key Type (RSA/DSA); `--expert` flag provides more types
	- Number of Bits (1024-4096)
	- Expiration Date
	- Comment (Not recommended)

```bash
gpg --gen-key
gpg --full-gen-key [--expert]
```

## Configure GPG & Git

First, set the `GPG_TTY` environment variable. Various programs use this to
communicate with the gpg agent.
```
export GPG_TTY=$(tty)
```

Now that you have a key created it's time to tell `git` about it.

By default, git uses gpg to sign commits.
However, if you want to be explicit, or override the global variable on a per-repo
basis use the following command

```bash
git config [--global/--local] gpg.format openpgp
```

Furthermore, the key to use also needs to be set.

Use the following command to list existing **secret** keys.
```bash
$ gpg --list-secret-keys --keyid-format=long
/home/kgb33/.config/gnupg/pubring.kbx
-------------------------------------
sec   rsa3072/USE-ME-123456 2022-10-26 [SC] [expires: 2024-04-18]
... # Omitted some entries
```

Look for the line with the following pattern and identitfy your `keyID`.:
```
sec	{keytype}{bits}/{keyID} {creationDate} [SC] [Expires: {experationDate}
```

Then, tell git to sign your commits using it.

```bash
git config [--global/--local] user.signingkey {keyID}
```

## Commit!
Now, you should be able to sign commits by passing the `-S` flag.

```bash
git commit -S
```

It's incredibly easy to forget the `-S` flag, luckily there is an option for that.
Set `commit.gpgsign` to true to always sign commits.

```bash
git config --global commit.gpgsign true
```

> Note: If for whatever reason you don't want to sign a commit,
> pass the `--no-gpg-sign` option.

## Unverified?

Great, you've pushed your first signed commit, you navigate to Github and
see it has an ugly *"unverified"* badge. This looks worse then no badge!

The solution is simple & retroactive. Simply add your public GPG key to your
Github account (under 'Settings' -> 'SSH and GPG Keys').

> Note: Github provides two handy URLs to access the keys associated with your
> account. `https://github.com/USERNAME.keys` for ssh keys
> and `https://github.com/USERNAME.gpg` for gpg keys.

## Uploading to a Key Server

For non-Github uses your public key needs to be shared with others. Luckily this is
a solved problem. Public Key Servers provide a location to share your keys,
and they share keys with other key servers.
There are four main flags to work with these servers:
  - `--send-keys`
  - `--search-keys`
  - `--recv-keys`
  - `--keyserver` (Overrides default, used in combination with the other flags.)

> Note: Notice the lack of a `--delete-keys` option? Because key servers share
> keys with each other deleting them causes all sorts of problems. Use your
> revocation certificate instead.

# Key Maintenance

While key Maintenance is important, it's also rare & falls into three main categories.

## Backup, Backup, Backup

To backup your private key use the following command.

```bash
gpg --export-secret-keys --armor --output filename keyID
```
Then import to import the key:

```bash
gpg --import filename
```

Technically only the private key needs to be backed up, everything else
can be (re)generated. However, it's a good idea to backup the revocation too.

```bash
gpg --gen-revoke --armor --output filename keyID
```

Because the revocation certificate can nullify your key, it's important to keep it
as secure as the private key.

## Revocation
It's important to keep your private key secure, but if, for whatever reason, it gets leaked you can revoke your key
to prevent impersonation. Import the revocation certificate, then upload the (now revoked) public key to
any servers that need it.

```bash
gpg --import revocation_cert
```

## Expiration

At some point your key *will* expire. Luckily you can extend the expiration date as needed.
The following command will drop you into an interactive menu. From there you can change the expiration
date by typing `expire`. Then, `save` to well, save.

```bash
gpg --edit-key keyID
```

Once you've updated your key, make sure to upload the 'new' public key to any services that need it.


# Extra Resources

Gpg is a very complex topic, and it's important to get right. The Arch Wiki
has a very in depth [article][arch-wiki-gpg] on it.


For more information on commit verification and using S/MIME & ssh keys see
Github's [documentation][gh-pki].


<!-- Links -->
[gpg-verified-badge]: /images/posts/gpg-verified-badge.png
[git2.34-changelog]: https://raw.githubusercontent.com/git/git/master/Documentation/RelNotes/2.34.0.txt
[arch-wiki-gpg]: https://wiki.archlinux.org/title/GnuPG
[gh-pki]: https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification
[cncf-sscp]: https://github.com/cncf/tag-security/blob/main/supply-chain-security/supply-chain-security-paper/sscsp.md#require-signed-commits
