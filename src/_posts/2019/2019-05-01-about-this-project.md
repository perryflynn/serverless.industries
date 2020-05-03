---
author: christian
title: Über dieses Projekt
lang: de
ref: about-this-project
tags: [ docker, git, continuous integration, projects ]
---

serverless.industries ist ein weiterer, von einem Nerd betriebener, Blog
welcher zum Dokumentieren und Teilen von technischen Dingen genutzt wird.

Dieser Blog ist jederzeit offen für Beiträge. Falls Du den einen oder
anderen Beitrag schreiben möchtest, schau in dem
[gitlab Repository des Blogs](https://git.brickburg.de/serverless.industries/blog)
vorbei und stelle ein Merge Request. (Die Registrierung von neuen Accounts
ist zur Zeit wegen Spam deaktiviert. Bitte sende mir eine Email und ich
erstelle den Account manuell.)

## Workflow

- git Repository klonen
- Neue Branch erstellen
- Blog Post als markdown Datei im Ordner `src/_posts/` erstellen
- Änderungen pushen
- Merge request stellen

## Technik

Die Inhalte dieses Blogs werden als statisch generiertes HTML ausgeliefert.
Erzeugt werden die HTML Dateien mit [Jekyll](https://jekyllrb.com/),
die gleiche Software welche auch für Github Pages verwendet wird.

Sobald Änderungen in das master Branch des git Repositorys eingecheckt werden,
wird ein gitlab-ci Job getriggert welcher mit Jekyll und Sass die Website neu rendert,
und anschließend die neu erzeugten HTML Dateien via SFTP auf den Webspace hoch lädt.

Außerdem wird für jede andere Branch eine Staging-Version der Website deployed,
welche man sich über eine separate Subdomain anschauen kann. Die Stages sind
mit Basic Authentication vor ungewollten Besuchern geschützt.

Wird ein Merge Request in die master Branch approved, sorgt ein weiterer gitlab-ci
Job dafür, dass die Stage Version wieder gelöscht wird und die Hauptseite
neu deployed wird.

**Weiterführende Links:**

- [Jekyll Quickstart](https://jekyllrb.com/docs/)
- [Jekyll & Sass](https://jekyllrb.com/docs/assets/)
- [gitlab: CI Configuration Reference](https://docs.gitlab.com/ce/ci/yaml/)
- [gitlab: Environments and deployments](https://docs.gitlab.com/ce/ci/environments.html)
