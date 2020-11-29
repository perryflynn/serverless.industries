---
author: christian
title: "minimon: Minimalistic Monitoring"
lang: de
ref: minimon
tags: [network, projects, http, bash, monitoring]
image: /assets/minimon.png
---

Seit dem [letzten Beitrag][prev] zu [minimon][minimon], einem minimalistischen Monitoring
Shell Script welches ich bei Wartungsarbeiten und bei Fehleranalysen benutze, hat sich
einiges an dem Script getan.

![minimon]({{'/assets/minimon.png' | relative_url}}){:.img-fluid}

[prev]: {% post_url 2020-11-07-tcp-service-checks-curl %}
[protos]: https://ec.haxx.se/protocols/protocols-curl
[exit]: https://ec.haxx.se/usingcurl/usingcurl-returns
[writeout]: https://ec.haxx.se/usingcurl/usingcurl-verbose/usingcurl-writeout
[minimon]: https://github.com/perryflynn/minimon
[bell]: https://en.wikipedia.org/wiki/Bell_character

## Funktionsweise

Das Script kann HTTP Dienste, generische TCP Ports und ICMP (ping) überwachen.
Beim Start des Scripts gibt man eine Liste an Services an, wobei mit einem
Semikolon getrennt der Service benannt kann.

Im Hintergrund werden `curl` (HTTP & TCP) und `ping` (ICMP) benutzt.

## IPv4 & IPv6

Es kann jetzt gewählt werden, ob explizit IPv4 oder IPv6 für einen
Test benutzt werden soll. Dazu hinter die entsprechende Option
eine `4` oder `6` schreiben.

```txt
--tcp host:port    Check a generic TCP port
--tcp4 host:port   Check a generic TCP port, force IPv4
--tcp6 host:port   Check a generic TCP port, force IPv6
--http url         Check a HTTP(S) URL
--http4 url        Check a HTTP(S) URL, force IPv4
--http6 url        Check a HTTP(S) URL, force IPv6
--icmp host        Ping a Hostname/IP
--icmp4 host       Ping a Hostname/IP, force IPv4
--icmp6 host       Ping a Hostname/IP, force IPv6
```

## Fehlerausgabe

Auch kann jetzt gesteuert werden, wann detailiertere Informationen
ausgegeben werden. `--verbose` gibt unabhängig vom Testergebnis immer
die Details aus, `--warnings` sobald ein Check auf `WARN` (zum Beispiel
bei einem HTTP STatus Code != 2xx) wechselt und `--errors` wenn ein Check
auf `CRIT` wechselt.

```txt
-v, --verbose      Enable verbose mode
-w, --warnings     Show warning output
-e, --errors       Show error output
```

## Weitere Optionen

Mit `--no-redirect` wird `curl` bei HTTP checks angewiesen, Weiterleitungen nicht
zu folgen. Der Check wird dann auf `WARN` mit einem 30x Status Code stehen bleiben.
`--invalid-tls` erlaubt es Services zu checken, welche kein gültiges TLS Zertifikat
besitzen.

```txt
--no-redirect      Do not follow HTTP redirects
--invalid-tls      Ignore invalid TLS certificates
```

## Kompatibilität

Das Script funktioniert in der git-bash unter Windows (MINGW), im Windows Subsystem
for Linux, und natürlich unter Linux.

Für `ping` musste eine Betriebssystem&shy;weiche
eingebaut werden, da Windows und Linux die Parameter unterschiedlich benennen.
