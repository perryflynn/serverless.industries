---
author: christian
title: "debconf: Install Debian Packages unattended"
locale: en
ref: debconf-unattended-install
tags: ['linux', 'ansible', 'debian']
toc: true
---

The developers of the [jitsi-meet][jitsi] project are currently working in a impressive
speed. From release to release there are so many changes, that only a
reinstall makes sense.

So I've automated the installation of jitsi.

The jitsi-meet Debian packages require user input at the installation.
This can be prevented with the `debconf` tool. It lets you predefine
the parameters.

## Find the parameters

To get the parameters from a package, the debian package `debconf-utils` is
required. After the installation we can use the tool `debconf-get-selections`
to get the parameters:

```sh
debconf-get-selections | grep -P "(jibri|jicofo|jigasi|jitsi)"
```

## Set parameters

Attention: If you predefine too many parameters, dpkg thinks this is a update
and don't do a initial setup. So just define the parameters which the package asks
for during the installation.

With a Shell:

```sh
echo "jitsi-videobridge2 jitsi-videobridge/jvb-hostname string meet.example.com" | debconf-set-selections
echo "jitsi-meet-web-config jitsi-meet/cert-choice select Generate a new self-signed certificate (You will later get a chance to obtain a Let's encrypt certificate)" | debconf-set-selections
```

With Ansible:

```yml
- name: "Configure jitsi-meet package"
  debconf:
    name: "jitsi-videobridge2"
    question: "jitsi-videobridge/jvb-hostname"
    vtype: "string"
    value: "meet.example.com"

- name: "Configure jitsi-meet package"
  debconf:
    name: "jitsi-meet-web-config"
    question: "jitsi-meet/cert-choice"
    vtype: "select"
    value: "Generate a new self-signed certificate (You will later get a chance to obtain a Let's encrypt certificate)"
```

At the installation with `apt-get`, all additional dialogs should be gone.

[jitsi]: https://jitsi.org/jitsi-meet/
