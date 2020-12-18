---
author: christian
title: "Docker Deployments mit Ansible und YAML Anchors"
lang: de
tags: [ ansible, yaml, docker ]
---

Gerade im semi&shy;professionellen oder im privaten Bereich macht es durchaus noch Sinn,
statt Kubernetes einfach einen normalen Docker Host zu betreiben.
Wenn man automatische Skalierung und ähnliches nicht benötigt, ist es schlicht
einfacher.

Nutzer von Ansible können dann Docker Compose Dateien auch durch
ein Ansible Playbook und Jinja2 Templates ersetzen.

So kann man sich auf eine Syntax konzentrieren und hat auch noch den Vorteil,
dass Jinja2 erheblich mehr kann, als die Templating Features von Docker Compose.

[anchorspec]: https://yaml.org/spec/1.2/spec.html#id2765878
[anchorexamples]: https://support.atlassian.com/bitbucket-cloud/docs/yaml-anchors/

## YAML Anchors

Mit [YAML Anchors][anchorspec] lassen sich Knoten in einem YAML Dokument wiederverwenden.
In diesem speziellen Fall, nutze ich die Anchors um die ganzen Standard&shy;einstellungen
für einen Docker Container in einen zentralen Knoten auszulagern.

```yml
defaults: &defaults
  foo: bar
  bar: foo
  foobar: barfoo

somenode:
  <<: *defaults
  foo: baz
  hello: world
```

Der YAML Parser erzeugt daraus folgendes:

```yml
somenode:
  bar: foo
  foobar: barfoo
  foo: baz
  hello: world
```

Nur im Anchor genannte Properties werden übernommen, auch im
eigentlichen Knoten genannte Properties werden überschrieben.

## Ein Beispiel

Folgendes Beispiel erzeugt Container für eine Matrix Installation.
Im `*container_defaults` Anchor nutze ich dabei Jinja2 Variablen,
welche innerhalb des `docker_container` Tasks definiert werden.

So lassen sich auch Berechnungen wie die CPU Quotas oder Konventionen wie das der
Containername auch als Hostname des Containers verwendet werden soll,
in die `*container_defaults` auslagern.

```yml
---

- name: Setup Matrix Synapse and Matrix Element
  hosts:
    - docker01.vpn.example.com

  vars:
    cleanupcontainer:
      - adminer
      - party
      - guacnginx

    cleandatafolders:
      - /mnt/cdata/party
      - /mnt/cdata/guacnginx
      - /mnt/cdata/guacnginx
      - /mnt/cdata/mynginx/nginx/conf.d/80-adminer.conf

    default_containersettings: &container_defaults
      name: "{{ "{{" }}containername}}"
      hostname: "{{ "{{" }}containername}}"
      pull: yes
      restart: no
      recreate: yes
      detach: yes
      networks_cli_compatible: yes
      restart_policy: unless-stopped
      state: started
      cpu_period: "{{ "{{" }}100000 if cpu_count is not none else None}}"
      cpu_quota: "{{ "{{" }}((cpu_count|float * 100000) | int) if cpu_count is not none else None}}"
      cpu_shares: 1024

  tasks:

    # -> Docker Credentials

    - name: Load secrets
      include_vars:
        file: ../secrets_docker.yml
        name: docker_secrets

    - name: Docker login
      docker_login:
        registry: "{{ "{{" }}docker_secrets.url}}"
        username: "{{ "{{" }}docker_secrets.username}}"
        password: "{{ "{{" }}docker_secrets.password}}"

    # -> Cleanup obsolete stuff

    - name: "Delete container"
      docker_container:
        name: "{{ "{{" }}item}}"
        state: absent
      loop: "{{ "{{" }}cleanupcontainer}}"

    - name: "Delete old data folders"
      file:
        path: "{{ "{{" }}item}}"
        state: absent
      loop: "{{ "{{" }}cleandatafolders}}"

    # -> Configure docker networks

    - name: Create containers0 network
      docker_network:
        name: containers0

    # -> Synapse

    # *snip*
    # generate config files for container
    # *snip*

    - name: Deploy matrix synapse container
      docker_container:
        <<: *container_defaults
        image: matrixdotorg/synapse:latest
        env:
          #SYNAPSE_SERVER_NAME: 'example.com'
          #SYNAPSE_REPORT_STATS: 'yes'
          GID: '991'
          UID: '991'
        networks:
          - name: containers0
        volumes:
          - "/mnt/cdata/matrix-synapse:/data"
          - "/etc/letsencrypt/example.com:/ssl/example.com:ro"
        memory: '512M'
        #command: 'generate'
      vars:
        cpu_count: 2
        containername: matrixsynapse

    # -> Element

    # *snip*
    # generate config files for container
    # *snip*

    - name: Deploy matrix element container
      docker_container:
        <<: *container_defaults
        image: vectorim/riot-web
        networks:
          - name: containers0
        volumes:
          - "/mnt/cdata/matrix-element/config.json:/app/config.json:ro"
        memory: '128M'
      vars:
        cpu_count: 2
        containername: matrixelement

    # -> Cleanup

    - name: Docker logout
      docker_login:
        registry: "{{ "{{" }}docker_secrets.url}}"
        username: "{{ "{{" }}docker_secrets.username}}"
        state: absent

    - name: Docker cleanup
      shell: |
        docker image prune --all --force
        docker builder prune --all --force
```

[Bei Atlassian][anchorexamples] gibt es noch mehr Beispiele, wie man Anchors benutzt.
