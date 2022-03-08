---
author: christian
title: Terraria Server in Docker
lang: en
ref: terraria-docker
tags: ['linux', 'docker', 'games']
---

Yesterday I wanted to play Terraria again. To have the
option for multiplayer later, I wanted to start
directly on a dedicated server.

The following script starts the Terraria inside of a
Docker Container without the need to create a Docker Image.

The Server binaries and world data are stored just in a folder of
the host system. Both will be mounted into a vanilla Debian Buster
Image.

```sh
docker stop terraria || true
docker rm terraria || true

chmod a+x /opt/docker-terraria/bin/TerrariaServer*

mkdir -p \
    /opt/docker-terraria/bin \
    /opt/docker-terraria/world

# - Download Dedicated Server from
#   http://terraria.org/
#   (Link at the bottom of the page)
# - Extract the linux binaries to
#   /opt/docker-terraria/bin

docker run -it -d \
    --name terraria \
    -p 7777:7777 \
    -v /opt/docker-terraria/bin:/root/bin/terraria \
    -v /opt/docker-terraria/world:/root/.local/share/Terraria \
    --workdir /root/bin/terraria \
    --entrypoint ./TerrariaServer.bin.x86_64 \
    debian:buster-slim \
        -players 50 \
        -motd "LadL 2022" \
        -port 7777 \
        -autocreate 3 \
        -worldname myworld \
        -world /root/.local/share/Terraria/Worlds/myworld.wld
```

The admin console of the server can be opened with
`docker attach terraria`. To close the console again,
use the keyboard shortcut `CTRL-p`, `CTRL-q`.

When the docker host runs more (maybe critical) stuff,
you may want to limit the ressources of the container
with `--memory` and `--cpus`.
