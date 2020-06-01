---
author: christian
title: "git-clean-sync.sh"
lang: de
ref: git-clean-sync.sh
tags: ['git', 'projects', 'bash', 'software development']
---

[git-clean-sync][git] ist ein Script welches eine lokale Arbeitskopie
eines git Repos mit der Remote synchronisiert. Das Script entstand als
Hilftsmittel für die Arbeit, wo ich in einem Entwicklerteam sehr viel mit
Branching, Merging, etc beschäftigt bin.

## Synchronisation

Das Script holt Änderungen von der Remote, ohne dass dabei das aktuell
ausgecheckte Branch verändert wird. Man kann also alle neuen Änderungen
ziehen, **ohne dass man Debugger oder Development Server beenden muss.**

## Link branches

Lokale und Remote Branches mit dem gleichen Namen werden verknüpft,
sodass der Push/Pull Prozess von git vernünftig funktioniert.

## Verwaiste Branches löschen

Wurde ein Feature Branch vom abschliessen eines Pull Requests gelöscht,
wird dieses Branch auch lokal gelöscht.

## Aktuelles Branch doch verändern

Möchte man das aktuelle Branch doch mit pullen/mergen, gibt es dafür eine
separate Funktion. Dabei wird ein temporäres Branch erstellt, der Sync
durchgeführt und danach wird wieder auf das vorherige Branch zurückgesprungen.

Wurde das vorherige Branch gelöscht weil es verwaist war, wird auf den master
Branch gewechselt.

## Informationen

Das Script zeigt außerdem auch detailierte Informationen über die aktuell
existierenden Branches an.

## Download

Das Script und eine detailierte Beschreibung zu den Optionen gibt es
auf [meiner github Seite][git].

[git]: https://github.com/perryflynn/git-utils

```sh
git-clean-sync -aaa --force
```

```txt
[i] Current directory: /home/christian/gitweb-repos/blog
[*] Create and checkout a temporary branch...
[>] git checkout -b tmp.a27yhjRcO1
[!] Switched to a new branch 'tmp.a27yhjRcO1'
[*] Fetch all changes from remote...
[>] git fetch --all --prune --tags
[<] Fetching origin
[<] Fetching github
[!] From git.brickburg.de:serverless.industries/blog
[!] - [deleted]         (none)     -> origin/foo
[*] Find unlinked local and remote branches with the same name and link them...
[>] git branch -vv
[*] Integrate changes into tracking branches...
[>] git branch -vv
[i] Found 1 tracked branches: master
[i] Skip branch 'master' because there are no incoming changes.
[*] Find orphaned branches...
[>] git branch -vv
[i] Found 1 orphaned branches.
[<]   foo            5918144 [origin/foo: gone] Merge branch 'php-sessions-suck' into 'master'
[*] Delete branch 'foo'...
[>] git branch -D foo
[<] Deleted branch foo (was 5918144).
[*] Push changes in tracking branches to the remotes...
[>] git branch -vv
[i] Found 1 tracked branches: master
[i] Skip branch 'master' because there are no outgoing changes.
[*] Checkout 'foo' and delete the temporary branch...
[>] git rev-parse --quiet --verify foo
[i] The branch foo doesn't exist anymore, use first branch in list.
[>] git branch -vv
[*] Checkout 'apple' as a replacement for 'foo'...
[>] git checkout apple
[!] Switched to branch 'apple'
[>] git branch -D tmp.a27yhjRcO1
[<] Deleted branch tmp.a27yhjRcO1 (was 5918144).
[*] Show the current state of all local branches...
[>] git branch -vv
[<] * apple      afd5fa8 text
[<]   master     5918144 [origin/master] Merge branch 'php-sessions-suck' into 'master'
[<]   netconsole 3bf5433 foo
[<]   pi4        6db2aae rename
[*] Show the current state of all remote branches...
[>] git branch -vv -r
[<]   github/master  5918144 Merge branch 'php-sessions-suck' into 'master'
[<]   origin/HEAD    -> origin/master
[<]   origin/master  5918144 Merge branch 'php-sessions-suck' into 'master'
[<]   origin/ulticon 3114d86 Merge branch 'master' into ulticon
```

