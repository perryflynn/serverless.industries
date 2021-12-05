---
author: christian
title: Check_MK Notifications via Signal Messenger
lang: de
tags: [ monitoring, check_mk, signal messenger ]
image: /assets/cmksignal.jpg
toc: yes
---

Wie viele andere Dinge auch kann man die Notification
Methoden in [Check_MK][cmk] durch simple Shell Scripte erweitern.
So haben wir jetzt einen Signal Bot, welcher uns über Störungen
informiert.

![Check_MK Signal Message]({{'assets/cmksignal.jpg' | relative_url}}){:.img-fluid}

[cmk]: https://checkmk.com/product/features
[signal-cli]: https://github.com/AsamK/signal-cli
[usage]: https://github.com/AsamK/signal-cli#usage
[notiscript]: https://docs.checkmk.com/latest/de/notifications.html#scripts
[congroups]: https://docs.checkmk.com/latest/de/wato_user.html#contact_groups

## signal-cli

Das wunderbare Projekt [signal-cli][signal-cli] macht die meiste Arbeit.
Hat man einmal einen Account registriert und verifiziert (siehe [usage][usage])
kann man mit simplen Shell Befehlen Nachrichten versenden.

ID der Chat Gruppe ermitteln:

```sh
./signal-cli --output=json -u +4955XXXXXX listGroups | jq
```

Nachricht an eine Chat Gruppe senden:

```sh
echo "Hello World!" | ./signal-cli -u +4955XXXXXX send -g c2VydmVybGVzcy5pbmR1c3RyaWVzCg==
```

## signal-cli Cronjob

Man sollte sich einen Cronjob anlegen, welcher eingehende Nachrichten
zirka alle fünf Minuten verarbeitet. Unter anderem werden so auch neue Schlüssel
heruntergeladen.

```sh
#!/bin/bash

set -u
set -e

# load configs
cd "$(dirname "$0")"

# fetch new messages
TS=$(date +%s)
ICFILE="incoming/$TS.json"

mkdir -p incoming

./signal-cli --output=json -u +4955XXXXXX receive > "$ICFILE"

# result
if [ -s "$ICFILE" ]; then
    echo "$(cat "$ICFILE" | wc -l) new messages"
else
    echo "No new messages"
    rm -f "$ICFILE"
fi
```

Im Unterordner `incoming/` werden dann eingehende Nachrichten aller Art
gesammelt. Will man diese nicht behalten, kann man den Ordner mit Tools wie
`find` bereinigen.

Dateianhänge finden sich in `~/.local/share/signal-cli/attachments` und lassen sich
über entsprechende IDs im JSON Output der signal-cli mit Nachrichten verknüpfen.

## SSH Gateway für signal-cli

Wegen anderer Projekte hatte ich bereits ein signal-cli auf meinem Jump Host laufen,
welches auch für Check_MK benutzt werden soll. Damit vom Check_MK Host Signal Nachrichten
verschickt werden können, wird ein SSH Wrapper auf dem Jump Host benötigt.

```sh
#!/bin/bash

set -u
export LANG="en_US.UTF-8"
cd "$(dirname "$0")"

# parse arguments
COMMAND_ARRAY=()
while read line; do
  COMMAND_ARRAY+=("$line")
done < <(xargs -n 1 <<< "$SSH_ORIGINAL_COMMAND")

# start signal messenger
cat | ./signal-cli -u +4955XXXXXX send -g "${COMMAND_ARRAY[0]}"
```

SSH Key hinterlegen:

```txt
command="/home/christian/signal-cli/sendwrapper-ssh.sh",restrict ssh-rsa AAAAB3NzaC1yc2EAAAADAQ...
```

SSH Wrapper testen:

```sh
echo "Hello World!" | ssh -i ~/.ssh/id_signalwrapper christian@jumphost -- c2VydmVybGVzcy5pbmR1c3RyaWVzCg==
```

SSH Piped das `Hello World!` an den Jump Host weiter, der SSH Key ForceCommand sorgt dafür, dass der
Wrapper gestartet wird, der Wrapper extrahiert die Group ID aus den Parametern und startet die
signal-cli.

## Signal Notification Provider

Das Anlegen [neuer Notification Provider][notiscript] ist simpel. Folgendes Script muss als
`/opt/omd/sites/sitename/share/check_mk/notifications/signal` angelegt werden.

Der SSH Key muss unter `/opt/omd/sites/sitename/.ssh/id_signalwrapper` abgelegt werden.

Der Kommentar in Zeile 2 des Scripts wird als Bezeichnung des Providers in der Check_MK
GUI verwendet.

```sh
#!/bin/bash
# Signal Brickburg Bot

export LANG="en_US.UTF-8"

if [ -z "$NOTIFY_CONTACTPAGER" ] || [[ ! $NOTIFY_CONTACTPAGER == signal-* ]]; then
    echo "No signal group name in 'pager address' field defined."
    exit 2
fi

recipient=$(echo "$NOTIFY_CONTACTPAGER" | sed 's/^signal-//g')
message=""

ICON_SERVER="🖥️"
ICON_SERVICE="⚙️"
ICON_ALERT="🚨"
ICON_OK="👍"
ICON_WARN="⚠️"
ICON_UNKN="🤷"

if [ "$NOTIFY_WHAT" == "HOST" ]; then

    hostname=$NOTIFY_HOSTNAME
    datetime=$NOTIFY_SHORTDATETIME
    duration=$NOTIFY_LASTHOSTSTATECHANGE_REL
    hoststate=$NOTIFY_HOSTSTATE
    lasthoststate=$NOTIFY_LASTHOSTSTATE

    hosticon="$ICON_ALERT"
    if [ "$hoststate" == "UP" ]; then
        hosticon="$ICON_OK"
    fi
    
    message="$ICON_SERVER $hosticon CMK Host: $hostname: $hoststate after $lasthoststate at $datetime ($duration ago)"

elif [ "$NOTIFY_WHAT" == "SERVICE" ]; then

    hostname=$NOTIFY_HOSTNAME
    servicename=$NOTIFY_SERVICEDESC
    datetime=$NOTIFY_SHORTDATETIME
    duration=$NOTIFY_LASTSERVICESTATECHANGE_REL
    servicestate=$NOTIFY_SERVICESHORTSTATE
    lastservicestate=$NOTIFY_LASTSERVICESHORTSTATE

    srvicon="$ICON_ALERT"
    if [ "$servicestate" == "OK" ]; then                                                                                            
        srvicon="$ICON_OK"                                                                                                          
    elif [ "$servicestate" == "WARN" ]; then
        srvicon="$ICON_WARN"
    elif [ "$servicestate" == "UNKN" ]; then
        srvicon="$ICON_UNKN"
    fi

    message="$ICON_SERVICE $srvicon CMK Service: $servicename @ $hostname: $servicestate after $lastservicestate at $datetime ($duration ago)"

fi

if [ -n "$message" ] && [ -n "$recipient" ]; then

    echo "$message" | ssh -i ~/.ssh/id_signalwrapper christian@ellen.lan.brickburg.de -- "$recipient"

else
    exit 2
fi

# eof
```

## Check_MK User

Der Notification Provider holt sich die ID der Ziel Signal Gruppe aus dem Feld `Pager address`
des jeweiligen Accounts. Also legen wir einen neuen Account an, und tragen dort die ID
mit `signal-` als Prefix ein.

Falls das `Pager address` Feld in anderen Accounts für andere Dinge benutzt werden sollte,
sorgt dass Prefix dafür dass dies vom Notification Provider erkannt wird und der Zustellversuch
abgebrochen wird.

![Notification Rule]({{'assets/cmksignal-user.png' | relative_url}}){:.img-fluid}

## Check_MK Notification Rule

Der Notification Provider sollte nun auswählbar sein:

![Notification Rule]({{'assets/cmksignal-notificationrule.png' | relative_url}}){:.img-fluid}

Wenn alles korrekt funktioniert, sollten nun die Benachrichtigungen an die Signal Gruppe
gesendet werden.

Verschiedene Gruppen kann man mit mehreren Notification Rules
und [Contract Groups][congroups] realisieren.

## Fehlersuche

Alle Komponenten sind simple Shell Scripte und können händisch aufgerufen werden.

Sollte es nicht funktionieren, kann man zum Beispiel den Notification Provider manuell aufrufen:

```sh
# as root
su sitename -c "( NOTIFY_WHAT=SERVICE NOTIFY_CONTACTPAGER=signal-c2VydmVybGVzcy5pbmR1c3RyaWVzCg== /opt/omd/sites/sitename/share/check_mk/notifications/signal )"
```
