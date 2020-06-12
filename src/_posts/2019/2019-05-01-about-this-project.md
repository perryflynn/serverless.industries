---
author: christian
title: Über dieses Projekt
lang: de
ref: about-this-project
tags: [ docker, git, continuous integration, projects ]
---

serverless.industries ist ein weiterer, von einem Nerd betriebener, Blog
welcher zum Dokumentieren und Teilen von technischen Dingen genutzt wird.

Dieser Blog ist offen für Beiträge. Falls Du den einen oder
anderen Beitrag schreiben möchtest, schau in dem
[gitlab Repository des Blogs](https://git.brickburg.de/serverless.industries/blog)
vorbei und stelle ein Merge Request. (Die Registrierung von neuen Accounts
ist zur Zeit wegen Spam deaktiviert. Bitte sende mir eine Email und ich
erstelle den Account manuell.)

## Workflow

- git Repository klonen
- Neuen Branch erstellen
- Blog Post als Markdown Datei im Ordner `src/_posts/` erstellen
- Änderungen pushen
- Merge Request stellen

## Technik

Die Inhalte dieses Blogs werden als statisch generiertes HTML ausgeliefert.
Erzeugt werden die HTML Dateien mit [Jekyll](https://jekyllrb.com/),
die Software welche auch für Github Pages verwendet wird.

Sobald Änderungen in das master Branch des git Repositorys eingecheckt werden,
wird ein gitlab-ci Job ausgelöst welcher mit Jekyll und SASS die Website neu erzeugt,
und anschließend via SFTP auf einen Webspace hochlädt.

Außerdem wird für jeden anderen Branch eine Staging-Version der Website deployed,
welche man sich über eine separate Domain anschauen kann. Die Stages sind
mit Basic Authentication vor ungewollten Besuchern geschützt.

Wird ein Merge Request in die master Branch übernommen, sorgt ein weiterer gitlab-ci
Job dafür, dass die Stage Version wieder gelöscht wird und die Hauptseite
neu deployed wird.

**Weiterführende Links:**

- [Jekyll Quickstart](https://jekyllrb.com/docs/)
- [Jekyll & Sass](https://jekyllrb.com/docs/assets/)
- [gitlab: CI Configuration Reference](https://docs.gitlab.com/ce/ci/yaml/)
- [gitlab: Environments and deployments](https://docs.gitlab.com/ce/ci/environments.html)
