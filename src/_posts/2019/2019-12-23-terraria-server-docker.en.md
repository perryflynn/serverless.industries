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
mkdir -p \
    /containerdata/terraria/server \
    /containerdata/terraria/world

# - Download Dedicated Server from
#   http://terraria.org/
#   (Link at the bottom of the page)
# - Unzip the binaries to
#   /containerdata/terraria/server

docker run -it -d \
    --name terraria \
    -p 7777:7777 \
    -v /containerdata/terraria:/data \
    --workdir /data/server \
    --entrypoint ./TerrariaServer \
    debian:buster-slim \
        -x64 \
        -players 20 \
        -worldpath /data/world \
        -world /data/world/myworld.wld \
        -port 7777 \
        -autocreate 3 \
        -worldname myworld
```

The admin console of the server can be opened with
`docker attach terraria`. To close the console again,
use the keyboard shortcut `CTRL-p`, `CTRL-q`.

When the docker host runs more (maybe critical) stuff,
you may want to limit the ressources of the container
with `--memory` and `--cpus`.
