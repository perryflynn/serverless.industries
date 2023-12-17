---
author: christian
title: The only Docker CE setup guide you will ever need
locale: en
tags: [ docker, network, debian ]
excerpt_separator: <!--more-->
changelog:
  - timestamp: 2023-12-16
    comment: Published
  - timestamp: 2023-12-17
    comment: Added build caching chapter
visible: false
---

Kubernetes clusters are an awesome piece of technology, if an highly automated and dynamic environment for
tens or hundrets of applications is required.

But Kubernetes brings also huge complexity which is not always necessary. Not every project scales
to the size of Netflix or Google, so an good old Docker CE can also be an option.

This guide is a collection of custom configurations to improve the security, stability and isolation of
Docker CE servers and it's containers.


<!--more-->


## Scope

- This is not a beginner guide
- All operating system settings are based on Debian Bookworm
- Single Docker CE servers, no Docker Swarm
- Some parts of this document cover IPv6, most don't


## Operating System and Docker Daemon

Configuration for the Docker CE Daemon and the underlying operating system.

### Installing Docker CE Daemon

Debian brings it's own packages for Docker CE, but it is recommended to use the official package sources
from Docker.

- Make sure that all Debian provided Debian packages are uninstalled
- Follow the instructions for [installing Docker CE using the apt repository](https://docs.docker.com/engine/install/debian/)

When Apt is done, `docker ps` should output an empty container list.

### Docker API access

The Docker CE Engine is controlled with an HTTP RESTful API accessible using the Unix Socket
`/var/run/docker.sock`. Whoever has access to that socket can run any action/query on the Docker CE Engine.

Example:

```sh
curl --unix-socket /var/run/docker.sock http://localhost/images/json | jq
```

(Shorted) Output:

```json
[{
    "Created": 1699617762,
    "Id": "sha256:3f32ac3a3d6f2c6778eb8ddb5924264e89c3673175e057caab233961b6eb3140",
    "RepoDigests": [ "homeassistant/home-assistant@sha256:400f20c77f52ac31334c1e73a2f19b2d6e5820757d1d476f01960b1efed31949" ],
    "RepoTags": [ "homeassistant/home-assistant:latest" ],
    "Size": 1903993749,
}]
```

Per default `root` and all members of the Unix group `docker` can read/write to the socket.

### Docker and privilege escalation

As mentioned in the last chapter, any Unix account can get access to Docker CE by being member 
of the group `docker`. But be aware, that all users which can create containers will have implicit 
root access to the whole server system.

There are alot examples how host access can be done via docker. As one example, a combination
of a privileged container and chroot:

```sh
# mount the hosts root partition into the container
# use the hosts network scope
# --privileged allows kernel access
# chroot into the hosts root partition
# launch a interactive bash
docker run -it --rm -v /:/mnt/host --net=host --privileged debian:latest chroot /mnt/host /bin/bash -i
```

If this is no/low risk for you, access to Docker CE for a user can be granted like so:

```sh
gpasswd -a christian docker
```

### Docker CLI Plugins

The `docker` CLI command supports plugins, the most used one should be `docker compose`, which is also available
as dedicated CLI command. 

On debian it can be installed like so:

```sh
apt install docker-compose-plugin docker-buildx-plugin
```

In a Dockerfile it can be installed like so:

```Dockerfile
FROM docker:latest
COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx
COPY --from=docker/compose-bin:latest /docker-compose /usr/libexec/docker/cli-plugins/docker-compose
```

The plugins can be used like so:

```sh
docker compose --help
docker buildx --help
```

### Dedicated Disk for Dockers Data Directory

{% capture msg %}
This chapter assumes that there is already a unformatted partition available and that this partition
has the device name `/dev/sda2` or `/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0-part2`.
{% endcapture %}
{% include box.html message=msg %}

To have better control of the disk space consumtion, it makes sense to move the Docker CE data directory
to a dedicated partition. If the partition has a XFS filesystem, it's even possible to use disk quotas
in docker volumes and containers.

Install dependencies, format partition, move data:

```sh
# preparations
apt install xfsprogs
systemctl stop docker

# format and mount partition
mkfs.xfs /dev/sda2
mkdir /mnt/dockerdata
echo "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0-part2 /mnt/dockerdata xfs discard,nofail,pquota,defaults 0 0" >> /etc/fstab
mount /mnt/dockerdata

# check if partition is mounted
mount | grep dockerdata

# move data
mv /var/lib/docker /mnt/dockerdata/docker
```

Add `data-root` setting in `/etc/docker/daemon.json`:

```json
{
    "data-root": "/mnt/dockerdata/docker"
}
```

Start docker again and verify if it has started correctly:

```sh
systemctl start docker
systemctl status docker
docker info | grep "Docker Root Dir:"
docker ps -a
```

### Limit Log Filesize

Depending of the container, a log file can grow very fast. To prevent running out of disk space, the size and number
of log files per container should be limited.

Add log driver options to `/etc/docker/daemon.json`:

```json
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "32m",
        "max-file": "5"
    }
}
```

Restart Docker CE:

```sh
systemctl restart docker
```

{% capture msg %}
All containers needs to be redeployed, as the log driver settings are set per-container. The setting
from `daemon.json` is just used as a default for each container deployment.
{% endcapture %}
{% include box.html message=msg type='warning' %}

### Log Drivers

There are also alternative log drivers available in Docker CE. A good option is for example, to use the
`journald` driver to log into systemd journald.

Logs can be accessed then like so:

```sh
journalctl CONTAINER_NAME=webserver
```

This also allows it to forward docker logs including all system log messages to applications like Graylog 
via [journalbeat][journalbeat].

Details:

[All Log Drivers](https://docs.docker.com/config/containers/logging/configure/#supported-logging-drivers)  
[Journald log driver documentation](https://docs.docker.com/config/containers/logging/journald/)  
[Journalbeat Documentation][journalbeat]

[journalbeat]: https://www.elastic.co/guide/en/beats/journalbeat/current/index.html


## Container Quotas

All containers should have quotas set to prevent, that a faulty process is affecting other containers
or even let the whole server system crash.

### CPU Quotas

CPU Quotas are supported out of the box.

See [Run containers](#run-containers) for examples.

### Memory + Swap Quotas

Memory quotas are supported per default, for swap quotas a kernel parameter needs to be set:

In `/etc/default/grub`:

```sh
GRUB_CMDLINE_LINUX_DEFAULT="quiet cgroup_enable=memory swapaccount=1"
```

Update bootloader and reboot:

```sh
update-grub
reboot
```

See [Run containers](#run-containers) for examples.

### Disk Quotas

Disk quotas are supported, if the [Dedicated Disk for Dockers Data Directory](#dedicated-disk-for-dockers-data-directory) chapter is applied correctly.

See [Run containers](#run-containers) for examples.


## Networking

Connecting Docker Containers to each other and to the outside world.

### Network Address Pools

Per default Docker CE is using the subnet `172.17.0.0/16` to assign IP addresses to containers and Docker
networks. Sometimes, this network is already in use by other services. This can result in the unavailability
of these services from the Docker server system and it's containers.

Add the `default-address-pools` option to `/etc/docker/daemon.json`:

```json
{
    "default-address-pools": [
        { "base": "172.19.0.0/16", "size": 24 }
    ],
}
```

Now Docker CE will create subnets with size size `/24` from `172.19.0.0/16` for new Docker networks.

{% include box.html type='warning' message='Containers and Docker networks needs to be recreated to activate this change.' %}

### Local Bridge Networks

The default way to connect docker containers with each other are bridge networks. When connected
to a network, the container can communicate with each other with it's container names.

```sh
docker network create -o com.docker.network.bridge.name=somenetwork somenetwork
docker run -d --name backend --network somenetwork debian:latest sleep infinity
docker run -d --rm --name frontend --network somenetwork debian:latest \
     /bin/bash -c "apt update && apt install --yes iputils-ping && ping backend"
```

The option `-o com.docker.network.bridge.name` allows it to set the name of the Linux network
interface. Which can be helpful to keep the overview. The name has a **maximum length of 15 characters**.

### Routed Bridge Networks

It is also possible to assign real LAN IP addresses directly to containers with the `macvlan` network driver.

The following network is attached to the server network interface `eth0`, 
which provides the LAN subnet `192.168.32.0/24`.

Containers connected to the network will have IP addresses from the range `192.168.32.128/25` assigned.
Services inside of this containers, are directly accessible from the server network without any port 
publishings (`-p`).

```sh
docker network create -d macvlan \
  --subnet=192.168.32.0/24 \
  --ip-range=192.168.32.128/25 \
  --gateway=192.168.32.254 \
  -o parent=ens18 publicservices
```

{% capture msg %}
For high thoughput applications with huge amounts of connections, this can improve the
performance significantly, as there is no NAT necessary. See also 
[this article](https://tech.new-work.se/a-reason-for-unexplained-connection-timeouts-on-kubernetes-docker-abd041cf7e02).
{% endcapture %}
{% include box.html message=msg %}

### Set outgoing IP Address by Docker Network

For outgoing communication, all containers in a `bridge` driver network using the primary IP address of 
the server system. This can be a problem, if every application on the docker host should have invidual 
firewall rules to allow communication with other servers and services.

An individual outgoing IP address can be defined, by managing the NAT rules ourselves.

Create a Docker network with disabled masquerading:

```sh
docker network create -d bridge \
    -o com.docker.network.bridge.name=appnetwork \
    -o com.docker.network.bridge.enable_ip_masquerade=false \
    appnetwork
```

Then the following nftables rule needs to be applied:

```nft
table ip docker_network_appnetwork
delete table ip docker_network_appnetwork

table ip docker_network_appnetwork {
    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        ip saddr 172.19.4.0/24 oifname != "appnetwork" snat to 192.168.99.226
    }
}
```

`172.19.4.0/24` is the subnet which was assigned to the Docker network, `appnetwork` the interface name and
`192.168.99.226` the IP address used for the outgoing connection.

{% include box.html type='warning' message='The outgoing IP address **must** exists on the server interface.' %}

On `macvlan` networks, it is alot easier, as a NAT rule is not necessary:

```sh
docker network create -d macvlan \
    --subnet=192.168.32.0/24 \
    --ip-range=192.168.32.128/25 \
    --gateway=192.168.32.254 \
    -o parent=ens18 \
    -o com.docker.network.bridge.enable_ip_masquerade=false \
    -o com.docker.network.bridge.name=appnetwork \
    appnetwork
```

### Internal Transit Docker Networks

When two applications which both using [custom outgoint IP addresses](#set-outgoing-ip-address-by-docker-network)
are required to be connected to each other, a transit network must be used. Otherwise one of the applications will
use the outgoing IP address of the other application, as it is not possible to control the routes inside of the
containers.

```sh
docker network create -d bridge --internal transitnetwork
```

The `--internal` option denies outgoing communication with that network. Only containers can communicate with
each other, but there no LAN or internet access possible.

### NAT and high traffic applications

When an application is processing thousands of connections per second, the default NATing of Docker can become
the bottleneck. Multiple connection trying to use the same port number for the NATing, which causes retries.
Because of that the initial connect can take multiple seconds.

The problem is described [here][xingnat] and [here][myipnat] more detailed.

Besides using `macvlan` networks, another option is to use the server host network stack:

```sh
# create a network with a known IP Subnet
docker network create --driver=bridge --subnet=10.0.0.0/24 containers0

# connect the existing application container with the network
# and assign a static IP address
docker network connect --ip 10.0.0.101 containers0 dingetun
docker network connect --ip 10.0.0.102 containers0 myip

# create the new webserver container
docker run --name webserver -d \
    --add-host dingetun:10.0.0.101 \
    --add-host myip:10.0.0.102 \
    --network host \
    nginx:latest
```

In this example the webserver container is directly attached to the network stack of the server host. Port
`80/tcp` and `443/tcp` are directly bound to the public IP of the server system.

Because of that, the container is unable to use Docker networks and the Docker DNS. This needs to workarounded
with assigning static IP addresses to all other containers and also add static `/etc/hosts` entries to
the webserver container.

With this, NAT is completly avoided, but other containers can still accessed by it's name.

[xingnat]: https://tech.new-work.se/a-reason-for-unexplained-connection-timeouts-on-kubernetes-docker-abd041cf7e02
[myipnat]: https://serverless.industries/2020/07/09/docker-without-nat.html


## Build Containers

Using the caching mechanics of Docker builds more effective.

### Cache packages

Docker checks for changes on all used files before (re)building an image layer. If there are no
changes, the layer from the previous build is used instead of building a new one.

This can be used to cache a `npm install` or a `nuget restore` run, even if the code of the app
itself was changed. Just copy the `package.json` and `package-lock.json` first into the image,
run the `npm install` and copy the rest of the application afterwards.

As long as this two files have no changes, this build step is cached and will safe multiple
minutes in future CI Pipeline runs.

```Dockerfile
FROM node:latest as packages
WORKDIR /src
COPY package.json package.json
COPY package-lock.json package-lock.json
RUN npm install

FROM packages as app
WORKDIR /src
COPY . .
RUN npm run-script build
```

### BuildX and inline caches

The "new" `docker buildx` includes cache metadata into the container image, which allows it to use an previous
image as a cache source. This makes the cache available even when two builds are done on different servers.

```sh
docker buildx build \
    --cache-from "example.com/myapp/myapp:latest" \
    --cache-to type=inline \
    -t "example.com/myapp/myapp:latest" .
```

Also this enables the use of caching in disposable build environments like GitLab runners with
Docker-in-Docker.

### Labels in images

Labels can be defined at build time and at runtime. Adding informations like build timestamp, version,
maintainer or application name helps to keep an overview about the applications which are running 
on the Docker system.

The [Open Containers Initiative](https://opencontainers.org/) has defined a standard to add metadata to a container 
image at build time. The format description can be found 
[here](https://github.com/opencontainers/image-spec/blob/main/annotations.md#annotations).

Dockerfile labels:

```Dockerfile
LABEL org.opencontainers.image.created=$DATE
LABEL org.opencontainers.image.version=1.0.0
LABEL org.opencontainers.image.authors=Christian
LABEL org.opencontainers.image.url=https://serverless.industries
```

Build command:

```sh
docker buildx build \
    --label "org.opencontainers.image.created=$(date --iso-8601=seconds)" \
    --label "org.opencontainers.image.version=1.0.0" \
    --label "org.opencontainers.image.authors=Christian" \
    --label "org.opencontainers.image.url=https://serverless.industries" \
    -t "example.com/myapp/myapp:latest" .
```


## Run Containers

### Container Quotas

The following example demonstates all quota options:

```sh
docker volume create -o size=1G persistent-volume
docker run -d --name cpu-demo \
    --cpus 1.5 \
    --memory 2GB \
    --memory-swap 3GB \
    --storage-opt size=1G \
    -v persistent-volume:/mnt/data \
    debian:latest
```

- Assign 1.5 CPUs
- Assign 2GB of memory
- Assign 1GB of swap
- Assign 1GB of temporary disk space
- Mount a volume with 1GB of persistent storage at `/mnt/data`

{% include box.html type='warning' message='Storage quotas on folder-to-folder bind mounts are not supported.' %}

### Name + Hostname

In addition to the container name, the container hostname should also be set as the hostname 
will appear in log files.

```sh
docker run -d \
    --name webserver \
    --hostname webserver \
    -p 80:80 \
    nginx:latest
```

### Labels on containers

Labels can also be set when creating containers. For example to group containers by project or 
adding a responsible person to the container. Also projects like [Traefik][traefik], 
[Watchtower][watchtower] or [Ofelia][ofelia] using labels for configuration and container 
discovery.

```sh
docker run -d \
    --name webserver \
    --label "applicationowner=John Doe" \
    --label "project=some-multi-container-project" \
    -p 80:80 \
    nginx:latest
```

[ofelia]: https://github.com/mcuadros/ofelia
[traefik]: https://doc.traefik.io/traefik/
[watchtower]: https://containrrr.dev/watchtower/
