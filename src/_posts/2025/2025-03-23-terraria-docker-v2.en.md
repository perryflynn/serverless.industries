---
author: christian
title: Run Terraria Server in Docker cleanly
locale: en
tags: ['linux', 'docker', 'games', shell]
---

Since I started to play Terraria again, I took the chance to improve my Dedicated Server Deployment 
for Docker. The server process has some weird behavior like [causing 100% CPU on one core][cpuissue] 
when no stdin is attached to the process and not saving the server when a SIGINT signal was sent.

For many of my projects I just use the default Debian Docker Image with a few additional 
tools and a unix account installed in it:

[cpuissue]: https://forums.terraria.org/index.php?threads/100-cpu-load-on-server-input-thread-on-dedicated-server.140550/

```Dockerfile
FROM debian:stable
WORKDIR /tmp
SHELL [ "/bin/bash", "-c" ]

# install packages
RUN	apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade && \
    apt-get install -qy coreutils procps dnsutils net-tools tini \
        apt-transport-https ca-certificates lsb-release curl wget && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

# add non-root user
RUN groupadd -r swuser -g 433 && \
  useradd -u 431 -r -g swuser -s /sbin/nologin -d /home/swuser -m -c "Docker image user" swuser

RUN mkdir -p /app && chown swuser:swuser /app

# startup parameters
WORKDIR /app
USER swuser
ENTRYPOINT [ "tini", "--" ]
CMD [ "/bin/bash" ]
```

I wasn't in the mood to create a Docker Image for Terraria, so I just put once again the server 
binaries on the host system into `/ctr/terraria/bin` and created `/ctr/terraria/data` 
to store the world data.

The following shell script is then handling the server process inside of the running container:

```sh
#!/bin/bash
# /ctr/terraria/bin/start.sh

# create console fifo
tercon=/tmp/terraria-console
mkfifo -m 600 $tercon

# setup signal traps
sigend() {
    >&2 echo "Server termination requested"
    echo "say Server is shutting down, bye" > $tercon
    sleep 2
    echo "exit" > $tercon
}

sigsave() {
    >&2 echo "World saving requested"
    echo "save" > $tercon
    echo "say World was saved triggered by SIGHUP signal" > $tercon
}

trap sigend SIGINT SIGTERM SIGQUIT
trap sigsave SIGHUP

# start terraria
tail -f $tercon | /app/TerrariaServer.bin.x86_64 \
    -noupnp -port 7777 \
    -players 5 -motd "$MOTD" \
    -autocreate 3 -worldname "$WORLDNAME" \
    -world "/home/swuser/.local/share/Terraria/Worlds/${WORLDNAME}.wld" &

tpid=$!

# event loop
while true
do

    if ps -p $tpid > /dev/null
    then
        sleep 0.1
    else
        >&2 echo "Server is not running anymore, abort."
        break
    fi

done
```

To be able to send commands to the Terraria Server from outside, it uses a FIFO. If data is 
piped into the FIFO file, it is piped into the STDIN of the Terraria Server process.

To ensure that the world is saved before the server is terminated, [two traps][traps] are set up. 
The first one triggers on SIGINT/SIGTERM, saves the map and exits afterwards. The second one 
triggers on SIGHUP and just saves the map without exiting.

The following script demonstrates how a command is sent to the [Named Pipe aka FIFO][fifo]:

[fifo]: https://en.wikipedia.org/wiki/Named_pipe
[traps]: https://www.linuxjournal.com/content/bash-trap-command

```sh
#!/bin/bash
# /ctr/terraria/bin/tcon.sh
tercon=/tmp/terraria-console
echo $@ > $tercon
```

Start container by shell:

```sh
docker run -d \
    --name terraria \
    --hostname terraria \
    -p 7777:7777 \
    -v /ctr/terraria/bin:/app \
    -v /ctr/terraria/data:/home/swuser/.local/share/Terraria \
    -e WORLDNAME=brickburg01 \
    -e MOTD="Welcome to Brickburg" \
    --restart unless-stopped \
    --memory 2048M \
    --cpus 3.5 \
    mycustomdebian:latest \
	/app/start.sh
```

Run Terraria command from outside of the container:

```sh
docker exec -it terraria /app/tcon.sh dawn
```
