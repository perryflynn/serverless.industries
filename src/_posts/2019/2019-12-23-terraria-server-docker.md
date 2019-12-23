---
author: christian
title: Terraria Server in Docker
language: german
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
mkdir -p \
    /containerdata/terraria/server \
    /containerdata/terraria/world

# - Download Dedicated Server von 
#   http://terraria.org/
#   (Link ganz unten im Footer)
# - Entpacken der Linux Binaries nach
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

Die Admin Konsole des Servers kann mit
`docker attach terraria` erreicht werden.
Geschlossen wird die Konsole mit der 
Tastenkombination `CTRL-p`, `CTRL-q`.

Falls noch mehr auf der Docker Instanz läuft,
bietet es sich noch an die Ressourcen mit den Optionen
`--memory` und `--cpus` zu beschränken.
