---
title: "Sops and Age"
date: 2023-01-08T21:03:27-08:00
tags: ["TiL", "sops", "age"]

draft: true
---
<!--more-->

Recently I've needed a more convenient & scalable way to manage secrets for
my various projects. Some of my requirements include:
  - Enables secrets to be versioned controlled.
  - Doesn't require additional infrastructure - i.e. HashiCorp Vault or AWS Secrets Manager.
  - Open Source


[SOPS][sops-repo] (*S*ecrets *OP*eration*S*) is a "simple and flexible tool for
managing secrets", and it matches all of my criteria.

It works nicely with git by making line wise changes - instead of scrambling
the whole file. Check out the [blame][sops-diff] on their `example.yaml`.

I don't need to spin up a complex server to use it - just add a directory
in `$XDG_CONFIG_HOME`.

Sops also has several methods to encrypt files, and a file
can be encrypted using multiple methods at once. In my case I'll
be using [`age`][age-repo].

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<pre
  class="command-line language-bash language-yaml"
  data-prompt="kgb33 >"
  data-output="2, 5, 8, 10-39"
>
  <code>
pacman -Syu age sops
...
mkdir -p $XDG_CONFIG_HOME/sops/age/
age-keygen -o $XDG_CONFIG_HOME/sops/age/keys.txt
Public key: age1rswjdjwg997gwj35lrpxf4km56s7z5wp9funzhe0drfzrlfjwc5q7ykyhm
sops -a age1rswjdjwg997gwj35lrpxf4km56s7z5wp9funzhe0drfzrlfjwc5q7ykyhm foo.yaml
ls
foo.yaml
cat foo.yaml
  </code>
</pre>

```yaml
hello: ENC[AES256_GCM,data:33WO6zuQnePN1PXt7Y/1pJ2vd7ysminB5zPf8FL8znqVW872CyaN6cGxHyTjAA==,iv:nnRRYnG5kwAkwm2NMu/ZBIsj2qRss/o7lJx9ITKZtnU=,tag:e+lVO9EvmmV122di7pawHg==,type:str]
ple_key: ENC[AES256_GCM,data:ClLs+wrb3EbCCHItpw==,iv:AnGO51gObJHwO2Fp7Ea1GW9+S+A9FDxBnzyfj9b8O4o=,tag:Tp+Q0SyA9mQAC1WtBGsrDw==,type:str]
[AES256_GCM,data:15B3iNkpmj69MjnXrpYpfjs=,iv:azLDwNsYe7rgiEV0cy1LlvOMin5fTzODd0HTBrv2CIA=,tag:OhWTEHXRkd7swEk6qTjJIg==,type:comment]
ple_array:
- ENC[AES256_GCM,data:1W7ZqbOq36BTDv+gUp8=,iv:gtpB3fnwmAugLcwiia/0D+eg8BbbJjFAW3db2Yow3Gw=,tag:FgSaieVIkLcGf83SnbJl5g==,type:str]
- ENC[AES256_GCM,data:s/ChH3F/7Ukg36Ikpjo=,iv:8yWCi0t+7YV5G3XCMpC4v8xAXqXDRSfcgGX06F3ePzg=,tag:2bK/y0d3aFZURxrQPvbExA==,type:str]
ple_number: ENC[AES256_GCM,data:yugG14+b2caLww==,iv:HFBS+5ZYPdi40EXFQoRNxHnJoHoPe1iDLRg8UR5xE0g=,tag:MXLqVJb1BWFN2ag0pBEHMQ==,type:float]
ple_booleans:
- ENC[AES256_GCM,data:mJhirw==,iv:Q9nTFWXeruVuWryusu38D+nyvot+zj6u8WO0VNVa3qA=,tag:Y/z/314z/Y9vLNtqzZMH4A==,type:bool]
- ENC[AES256_GCM,data:w4FZGaw=,iv:9j6IQeDVKi1Ka9Jj+PjEid19ScXYmm/+j+gpIAlNJ2I=,tag:iwIxWc4+a/YY6mUKIM6SBw==,type:bool]
:
kms: []
gcp_kms: []
azure_kv: []
hc_vault: []
age:
    - recipient: age1q7ep9a2lapepu20hn0syg0h2hya6lynumh66sey3vkxcg9a35qsq7yza3r
      enc: |
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSB6ZTQ0NlNRUloveUdYWjZq
        c0NYUlZwanE4VDlkZWF0MmVMOFhPeWRnU2lzCkR1bE9nUER2cjVPby9nc1lHUVdP
        UDRIRnlPNEFoWEJrZUZCV0pwY2tsZlkKLS0tIEhWV0U0MTRKRENTWHJkWGVEem1U
        RGo4Ym5JL1NhSDQxSzNrN3FiV0J4Q0UKqBZzFm1tGVLWtdooGPl/S58V3DqDxEir
        YF2t15LPMo0HjYFjWGA4TfDEDYPLBh662e0v1jSx+epdClmm6dQqVQ==
        -----END AGE ENCRYPTED FILE-----
lastmodified: "2023-01-09T17:11:57Z"
mac: ENC[AES256_GCM,data:zRI1mqwVMHHQ5tgDxZ0aMH2+sl/DvmL9h2/tfyFQubq2rlVZv/Y74zEoli3J13aF5ZRx0/06YenJ5cJz6bG8/77xMI0rsGCETS1YJKc9WP0SiTahO+BSPrW7UYw8ED+8hFMqqnz/wXouoBKvYPXxfM7OumzU7J2xERG6BPuvpkc=,iv:gXsTStUS8QhGqRt+3aFQBUQVnevhpegi//wlLUxuokQ=,tag:w8TAShyut2XQfWEagBcNBg==,type:str]
pgp: []
unencrypted_suffix: _unencrypted
version: 3.7.3
```

> Note: your Private & Public age key(s) are stored unencrypted
> in `$XDG_CONFIG_HOME/sops/age/keys.txt`

<!-- links -->
[sops-repo]: https://github.com/mozilla/sops
[sops-diff]: https://github.com/mozilla/sops/blame/master/example.yaml

[age-repo]: https://github.com/FiloSottile/age
