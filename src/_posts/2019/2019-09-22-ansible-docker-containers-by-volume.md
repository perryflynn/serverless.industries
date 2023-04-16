---
author: christian
title: Docker Container via Volume finden
locale: de
ref: ansible-docker-volume-find
tags: [docker, ansible, 'infrastructure code']
---

Hat [acme.sh][acmesh] neue Zertifikate erzeugt welche anschließend mit
[Ansible][ansible] auf die jeweiligen Server Systeme verteilt werden,
müssen neben normalen systemd Services auch Docker Container neu gestartet
werden, welche die Zertifikate via Volume eingebunden haben.

[acmesh]: https://github.com/Neilpang/acme.sh
[ansible]: https://www.ansible.com/overview/how-ansible-works

{% raw %}
```yml
# install jq as a dependency on the remote system
-
    name: Install jq
    package:
        name: jq
        state: present

# do a inspect on all docker containers,
# search with jq in the JSON for all
# containers which using a volume path starting with /etc/letsencrypt
-
    name: Find container which are using certificates
    shell: "docker inspect $(docker ps --format \"{{'{{'}}.ID{{'}}'}}\") | jq '[ .[] | { name: .Name, mounts: [ .Mounts[].Source ] } | select(.mounts | any(startswith(\"/etc/letsencrypt/\"))).name ]'"
    register: certcontainersresult

# deserialize the json for ansible
# use an empty array if the string is empty
-
    name: Parse docker inspect output
    set_fact:
        certcontainers: "{{('[]' if certcontainersresult.stdout == '' else certcontainersresult.stdout) | from_json}}"

# loop through all containers and restart them
-
    name: Restart all containers which using one of the certs
    docker_container:
        name: "{{item}}"
        state: "started"
        restart: yes
    loop: "{{certcontainers|default([])}}"
```
{% endraw %}

Der `docker inspect` Befehl liefert JSON, welches mit dem sehr praktischen Tool `jq` durchsucht
werden kann. Als Ergebnis dieses Befehls erhält man ein einfaches JSON Array mit
allen Container Namen welche Lets Encrypt Zertifikate verwenden:

```json
[
  "/container01",
  "/container02"
]
```

Der JSON String kann anschließend von Ansible deserialisiert werden und
in der `loop` Anweisung zum Container Neustart verwendet werden.
