---
author: christian
title: Terraria Server in Docker
lang: de
ref: terraria-docker
tags: ['linux', 'docker', 'games']
---

Gestern hatte ich mal wieder Lust Terraria
zu spielen. Um später vielleicht Multiplayer
spielen zu können, gleich auf einem dedicated Server.

Folgendes Schnipsel kapselt den Server
in einen Docker Container, ohne ein eigenes
Docker Image dafür bauen zu müssen.

Die Server Binaries und die Welt-Daten werden
einfach in einen Ordner entpackt und danach in
einen Debian Buster Container eingebunden und
gestartet.

```sh
docker stop terraria || true
docker rm terraria || true

chmod a+x /opt/docker-terraria/bin/TerrariaServer*

mkdir -p \
    /opt/docker-terraria/bin \
    /opt/docker-terraria/world

# - Download Dedicated Server von
#   http://terraria.org/
#   (Link ganz unten im Footer)
# - Entpacken der Linux Binaries nach
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

Die Admin Konsole des Servers kann mit
`docker attach terraria` erreicht werden.
Geschlossen wird die Konsole mit der
Tastenkombination `CTRL-p`, `CTRL-q`.

Falls noch mehr auf der Docker Instanz läuft,
bietet es sich noch an die Ressourcen mit den Optionen
`--memory` und `--cpus` zu beschränken.
