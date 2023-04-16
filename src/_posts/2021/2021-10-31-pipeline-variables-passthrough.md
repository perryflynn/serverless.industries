---
author: christian
title: Pipeline Variablen durchreichen
locale: de
tags: [ gitlab, azure pipelines, continuous integration, 'infrastructure code', ansible ]
---

Immer dann wenn Pipelines beziehungsweise Builds oder Deployments so kompliziert
werden, dass man weitere Tools wie Docker oder Ansible einbaut, muss man
Pipeline Variablen an diese Tools durchreichen.

GitLab CI Nutzer sind da verwöhnt. Die Pipeline läuft in einem Container
der normalerweise alle benötigten Tools enthält.

Für Azure Pipelines gibt es eine identische Mechanik mit den "neuen"
[YAML Container Jobs][azurecontainer]. Dies gibt es aber nicht in den
klassischen klicky-bunti Releases, welche manuelle Deployments auf verschiedene
Umgebungen per Klick ermöglichen.

![Azure Pipeline Releases]({{'assets/azure-pipelines-releases.jpg' | relative_url}}){:.img-fluid}

[azurecontainer]: https://docs.microsoft.com/en-us/azure/devops/pipelines/process/container-phases?view=azure-devops

## ENVs an Docker durchreichen

Da sich in den Environment Variablen nicht nur die der Pipeline befinden sondern
auch die Standards des Windows- oder Linux Systems, sollte man sich an eine Liste definieren.

Diese Liste ist auch wieder eine Variable:

```sh
APPBASE=/var/www/html/myapp
WEBBASE=/myapp/
ENABLE_EXPERIMENTAL_FEATURES=false
BUILD_BUILDNUMBER=1.1.42
DOCKER_ENVLIST=appbase webbase enable_experimental_fetures build_buildnumber
```

Die Liste in `$DOCKER_ENVLIST` wird dann in folgendem Schnipsel verwendet, um
die Environment Variablen für `docker run` dynamisch zu erzeugen:

```sh
# inline script as bash task in the release pipeline
ENVARGS=()
for I in $DOCKER_ENVLIST; do
    if [ -n "$I" ]; then
        # upper case variable name
        SOURCENAME=$(echo $I | sed -r -e 's/(.*)/\U\1/g')
        # -e VARNAME=value ...
        ENVARGS+=( -e "${SOURCENAME}=${!SOURCENAME}" )
    fi
done

docker run -i --rm \
    -v "`pwd`:/src" --workdir /src \
    -e "DOCKER_ENVLIST=${DOCKER_ENVLIST}" \
    "${ENVARGS[@]}" \
    ansible:latest \
    ansible-playbook run-deployment.yml
```

## ENVs an Ansible durchreichen

Auch in dem Ansible Playbook welches in dem Toolchain Docker Container ausgeführt wird kann wieder die `$DOCKER_ENVLIST`
verwendet werden. Wieder wird eine Liste von Konfigurations&shy;variablen erzeugt, diesmal aber für das
Deployment der Anwendung selbst.

```yml
---
# run-deployment.yml
- name: Deploy Apps
  hosts: all

  vars:
    # get the envlist, split by space into a list
    envlist: "{{'{{'}} (lookup('env', 'DOCKER_ENVLIST') | default('', True)).split(' ') | select('ne', '') | list }}"
    # version to deploy as container
    containerversion: "{{'{{'}}lookup('env', 'BUILD_BUILDNUMBER') | default('', True)}}"

  tasks:

    - name: Build container environment variables
      set_fact:
        # append all envlist items to the container_envs dict
        # and prefix each field with MYAPP_
        container_envs: >-
          {{'{{'}} container_envs | default({}) | combine({ 'MYAPP_' ~ (item | upper): lookup('env', item | upper) | default('', True) }) }}
      loop: "{{'{{'}}envlist}}"

    - name: Deploy Containers
      docker_container:
        image: "myappcontainer:{{'{{'}}containerversion}}"
        pull: yes
        recreate: yes
        name: myapp
        state: started
        restart_policy: always
        env: "{{'{{'}}container_envs}}"
```

## Platzhalter ersetzen

Bei der Anwendung, um die es in diesem Beispiel geht, werden Konfigurationsparameter nachträglich in den
App Code eingesetzt. In der minifizierten Java Script Datei befinden sich viele, viele Platzhalter alá
`__WebBase__` oder `__Enable_Experimental_Features__`.

Diese müssen beim Deployment durch die echten Werte ersetzt werden.

Die Anwendung läuft in einem `nginx:latest` Docker Image, welches glücklicherweise das Verzeichnis
`/docker-entrypoint.d` mitliefert, wo man beliebige Script ablegen kann, die beim Start des Containers
ausgeführt werden. Sehr praktisch.

Das Script `/docker-entrypoint.d/envsubst.sh`:

```sh
#!/bin/bash

# find all MYAPP variables
MYAPPVARS=$(env | grep -P "^MYAPP_" | cut -d= -f1)

# create a list which variables should be substituted
# ${MYAPP_APPBASE} ${MYAPP_WEBBBASE} ...
MYAPPVARSSUBST=$(env | grep -P "^MYAPP_" | cut -d= -f1 | sed -r -e 's/(.*)/${\U\1}/g' | tr '\n' ' ')

# we should keep all files which require substitution in the original, unmodified version
# copy a unmodified version
cat /templates/main.js > /templates/main.js.tpl
cat /templates/callback.html > /templates/callback.html.tpl
cat /templates/index.html > /templates/index.html.tpl

# transform __VAR__ into ${MYAPP_VAR} tokens to make it work with envsubst
while read APPVAR; do
    # remove variable prefix
    NAME=$(echo "$APPVAR" | sed -r 's/^MYAPP_//g')

    # __VAR__ --> ${MYAPP_VAR}
    sed -i -r -e "s/__${NAME}__/\${MYAPP_${NAME}}/gi" /templates/main.js.tpl
    sed -i -r -e "s/__${NAME}__/\${MYAPP_${NAME}}/gi" /templates/callback.html.tpl
    sed -i -r -e "s/__${NAME}__/\${MYAPP_${NAME}}/gi" /templates/index.html.tpl
done <<< "$MYAPPVARS"

# replace the fixed list of tokens 
# with the environment variables values
envsubst "$MYAPPVARSSUBST" < /templates/main.js.tpl > /usr/share/nginx/html/main.js
envsubst "$MYAPPVARSSUBST" < /templates/callback.html.tpl > /usr/share/nginx/html/implicit/callback/index.html
envsubst "$MYAPPVARSSUBST" < /templates/index.html.tpl > /usr/share/nginx/html/index.html
```

Das Unix Tool `envsubst` ist leider ziemlich dumm. Befinden sich in der Java Script Datei neben den eigentlichen
Variablen weitere Zeichenketten die wie Variablen aussehen, werden diese durch Leerstrings ersetzt und verursachen
Syntax Fehler im Java Script.

Daher muss man `envsubst` explizit mitgeben, welche Variablen ersetzt werden sollen.

## Fazit

IMHO lohnt es sich, diese Schnipsel in die Pipeline einzubauen, und damit die üblichen Listen
an Variablen an verschiedenen stellen im Pipeline Code durch eine einzelne `$DOCKER_ENVLIST` zu ersetzen.

Während der eigentlichen Entwicklung muss man sich dann nicht weiter um die Konfigurations&shy;parameter
kümmern, da alles magisch von alleine funktioniert.

Schöner wäre allerdings eine ähnlich komfortable Integration wie es sie in GitLab gibt.
