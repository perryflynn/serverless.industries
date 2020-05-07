---
author: christian
title: "debconf: Debian Pakete unbeaufsichtigt installieren"
lang: de
ref: debconf-unattended-install
tags: ['linux', 'ansible', 'debian']
toc: true
---

Die Entwickler von [jitsi-meet][jitsi] arbeiten aktuell mit einer enormen
Geschwindigkeit. Von Release zu Release ändern sich so viele Dinge, dass
es meistens nur Sinn macht, eine Neuinstallation vorzunehmen.

Aus dem Grund habe ich die Installation von jitsi vollautomatisiert.

Die Debian Pakete von jitsi erfordern Nutzereingaben während der Installation.
Diese lassen sich mit dem Tool `debconf` vorher definieren, sodass die Dialoge
bei der eigentlichen Installation nicht mehr auftauchen.

## Parameter auslesen

Für das Auslesen wird das Paket `debconf-utils` benötigt.
Anschließend kann man das Tool `debconf-get-selections` dazu verwenden, die Parameter
der Pakete auszulesen:

```sh
debconf-get-selections | grep -P "(jibri|jicofo|jigasi|jitsi)"
```

## Parameter festlegen

Achtung: Wenn man zu viele Parameter vor der Installation festlegt, kann dpkg
annehmen, dass das Paket bereits installiert war und führt daher keine Ersteinrichtung
durch.

Man sollte nur die Parameter festlegen, nach denen auch bei der manuellen Installation
gefragt wird.

Via Shell:

```sh
echo "jitsi-videobridge2 jitsi-videobridge/jvb-hostname string meet.example.com" | debconf-set-selections
echo "jitsi-meet-web-config jitsi-meet/cert-choice select Generate a new self-signed certificate (You will later get a chance to obtain a Let's encrypt certificate)" | debconf-set-selections
```

Via Ansible:

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

Bei der anschließenden Installation der Pakete via `apt-get` sollten keine weiteren Dialoge
erscheinen und die Pakete sollten ohne Probleme installiert werden.

[jitsi]: https://jitsi.org/jitsi-meet/
