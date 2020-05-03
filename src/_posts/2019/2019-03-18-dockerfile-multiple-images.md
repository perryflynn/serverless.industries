---
author: christian
title: Mit einem Dockerfile mehrere Images bauen
lang: de
ref: docker-multiple-images
tags: [linux, docker, gitlab]
---

Innerhalb eines Dockerfiles ist es möglich, mehrere Images zu definieren
und diese mit einer gitlab-ci Pipeline nacheinander zu bauen. Möglich wird dies durch
die Angabe eines Namens für ein Image, welcher als Filter für den `docker build`
Befehl genutzt werden kann.

```
# image with basic tools
FROM debian/stable-slim AS base

RUN apt-get update && \
    apt-get -y install git curl wget ca-certificates && \
    apt-get -y clean

# image with basic tools and php-cli
FROM base AS dev-php

RUN apt-get update && \
    apt-get -y install php7.0-cli && \
    apt-get clean

ENTRYPOINT [ "/bin/bash", "-c" ]
CMD [ "php" ]

# image with basic tools and python3
FROM base AS dev-python

RUN apt-get update && \
    apt-get -y install python3 && \
    apt-get clean

ENTRYPOINT [ "/bin/bash", "-c" ]
CMD [ "python3" ]
```

Das Dockerfile wird von oben nach unten abgearbeitet.

- Es wird ein Image mit diversen Werkzeugen als Basis erstellt
- In einem weiteren Image, welches `base` verwendet, wird zusätzlich php installiert
- In einem weiteren Image, welches `base` verwendet, wird zusätzlich python installiert

In der `.gitlab-ci.yml` können nun in separaten Jobs die Images gebaut werden.

```yml
stages:
  - build

variables:
  imageversion: "nightly"
  pushtag: "${CI_PROJECT_NAME}:${imageversion}"

build:php:
  image: docker:stable
  stage: build
  script:
    - 'docker build --target dev-php -t ${pushtag}-phpcli .'

build:python:
  image: docker:stable
  stage: build
  script:
    - 'docker build --target dev-python -t ${pushtag}-python .'
```

In den Gitlab-Ci Jobs wird `docker build` mit der Option `--target`
aufgerufen, welche angibt, welches Image das Ziel des builds sein soll.