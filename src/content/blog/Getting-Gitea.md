---
title: "Getting Going with Gitea"
pubDate: "2022-01-23"
tags: ["gitea","git","nginx","ssh"]

draft: false
---

[Gitea][gitea-home] describes itself as a painless self-hosted Git service.
It has many of the same features as Git[hub/lab], but is much more
lightweight.

This deployment runs in a Docker container on a Ubuntu 21.10 server.
The whole deployment uses ~2% of one CPU core, and ~2GB of RAM.
Easily runnable on a Raspberry Pi.

<!--more-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Prerequisites](#prerequisites)
- [Docker Compose Configuration](#docker-compose-configuration)
- [Setting up ssh](#setting-up-ssh)
- [Networking](#networking)
  - [HSTS Background](#hsts-background)
  - [Nginx Proxy and LetsEncrypt](#nginx-proxy-and-letsencrypt)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Prerequisites
  - Docker & Docker Compose
  - nginx
  - A Linux server

> Note: The user running the docker container on the server
> should be named `git`. This allows for the nice `scp` like
> git URL.

# Docker Compose Configuration

Gitea has a great Docker setup documentation [here][gitea-docker].
The git user is a member of the docker group, so even though docker
(and docker-compose) commands are not prefixed by `sudo` they
are still run by the root user.

The diff between the docker-compose.yaml provided by Gitea and
the one used to deploy `git.kgb33.dev` is as follows:

<pre class="line-numbers language-diff-yaml diff-highlight">
  <code>
  version: "3"

  networks:
    gitea:
      external: false

  services:
    server:
      image: gitea/gitea:1.15.10
      container_name: gitea
      environment:
        - USER_UID=1000
        - USER_GID=1000
+       - GITEA__database__DB_TYPE=postgres
+       - GITEA__database__HOST=db.5432
+       - GITEA__database__NAME=gitea
+       - GITEA__database__USER=gitea
+       - GITEA__database__PASSWD=gitea
+       - GITEA__server__DOMAIN="git.kgb33.dev"
+       - GITEA__server__SSH_DOMAIN="git.kgb33.dev"
      restart: always
      networks:
        - gitea
      volumes:
        - ./gitea:/data
        - /etc/timezone:/etc/timezone:ro
        - /etc/localtime:/etc/localtime:ro
      ports:
        - "3000:3000"
        - "2222:22"
+     depends_on:
+       - db

+   db:
+     image: postgres:13
+     restart: always
+     environment:
+       - POSTGRES_USER=gitea
+       - POSTGRES_PASSWORD=gitea
+       - POSTGRES_DB=gitea
+     networks:
+       - gitea
+     volumes:
+       - ./postgres:/var/lib/postgresql/data
  </code>
</pre>

The environment variables in the form `GITEA__foo__BAR` can also be changed in
the `./gitea/gitea/conf/app.ini` file. For a full list of variables check out
the [Configuration Cheat Sheet][gitea-conf].
> Note that `app.ini` is located in the volume mounted on line 25.

Setting `GITEA__server__DOMAIN` and `GITEA__server__SSH_DOMAIN` to
`git.kgb33.dev` changes the provided clone link to the correct domain,
instead of `localhost`.

![Gitea click-to-clone link][img-click-to-clone]

# Setting up ssh

Enabling ssh can seem a bit tricky. The request must be routed from the users computer,
though the firewall, to the host machine, then finally into the guest container.

![ssh-network-diagram][img-ssh-network-diagram]

Gitea has documentation on how to forward ssh requests from the host to the guest
[here][gitea-ssh]. In a nutshell the user running the container
and the user running Gitea inside the container must share some properties. They must have
the same `USER_UID`, `USER_GID`, and username (in this case `git`). Furthermore, they must
have the same ssh keys. This is accomplished by adding the server-user's `.ssh` directory
as a volume within the container.

However, by changing the host port that Gitea listens on we can bypass ssh forwarding.
Additionally, admins are still able to ssh in on the default port to manage configurations
on the host machine. This is only possible because the ssh traffic can be redirected at the
router level when the Port Forwarding rule is setup.

I don't particularly want to open any ports less than 1024 on my home network,
but I also want to use the scp-like syntax for the git URLs. A nice compromise
is to open a non-reserved port on the firewall, redirect ssh requests on that
port to the port on the host that Gitea is listening on. Then have a configuration
entry in `~/.ssh/config` as follows.

```
Host git.kgb33.dev
Hostname git.kgb33.dev
Port 2222
User git
```

Now whenever ssh attempts to connect to `git.kgb33.dev` as `git` it will automatically use
port 2222. This port is redirected to the host, and from there to the container.


Ssh keys are added to Gitea via the user's account in almost the exact same method as
Github.


# Networking
Gitea provides a web interface to manage accounts and repositories.

![HTTPs request flow][img-http-network-diagram]

To access from the internet two ports need to be forwarded.
Port `443` needs to be forwarded to the nginx proxy server. Whereas
the ssh port (in this case `2222` needs to be forwarded to the Gitea host.
Ensure both ports are forwarded to the ports on the hosts that Nginx and Gitea
are listening on.

## HSTS Background
Some domains are hard-coded in chromium and Firefox to automatically redirect
`http` requests to `https`. `*.dev` is one of these. Google manages the HSTS preload list
and more information can be found [here][HSTS-doc]. As a result, `git.kgb33.dev` must
have an HTTPs certificate.

## Nginx Proxy and LetsEncrypt

Traffic for this website (`blog.kgb33.dev`) and Gitea (`git.kgb33.dev`) both enter
the network on the HTTPs port 443. This port is mapped to a Nginx proxy which then redirects
traffic biased on the sub-domain.

To setup the `git` sub-domain create a new file under `/etc/nginx/site-avalable/` on the
nginx server with the following contents.

```
server {
        server_name git.kgb33.dev;

        location / {
            proxy_pass  http://<GITEA-SERVER-IP>:3000;
			proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        	proxy_set_header Host $http_host;
        	proxy_set_header X-Forwarded-Proto https;
        	proxy_redirect off;
        	proxy_http_version 1.1;
        }
}
```

> Note that the traffic is redirected as insecure http. This allows all certificates to
be managed on the central nginx server.

Enable the site using a symlink.

```
sudo ln -s /etc/nginx/sites-available/blog /etc/nginx/sites-enabled/blog
```
Lastly, configure and run `certbot`. I've already
covered getting certificates with nginx and certbot [here][self-certbot].

<!-- Links -->
[gitea-home]: https://gitea.io/en-us/
[gitea-docker]: https://docs.gitea.io/en-us/install-with-docker/
[gitea-conf]: https://docs.gitea.io/en-us/config-cheat-sheet/
[gitea-ssh]: https://docs.gitea.io/en-us/install-with-docker/#ssh-container-passthrough

[HSTS-doc]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security

[img-click-to-clone]: ../../static/images/posts/gitea-click-to-clone.png
[img-ssh-network-diagram]: ../../static/diagrams/gitea/ssh_path.png
[img-http-network-diagram]: ../../static/diagrams/gitea/https_path.png

[self-certbot]: /blog/getting_started_with_hugo/#lets-encrypt-auto-certs-via-cloudflare-dns
