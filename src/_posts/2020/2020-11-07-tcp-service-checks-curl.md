---
author: christian
title: "Verbindungstests mit curl"
lang: de
ref: minimon
tags: [network, projects, http, bash, monitoring]
---

Das großartige Programm `curl` beherrscht neben HTTP auch
[viele andere Protokolle][protos], darunter auch `telnet`.
Damit ist `curl` eine super Alternative, sollte auf einem
Computer mal kein `telnet` installiert sein.

[protos]: https://ec.haxx.se/protocols/protocols-curl
[exit]: https://ec.haxx.se/usingcurl/usingcurl-returns
[writeout]: https://ec.haxx.se/usingcurl/usingcurl-verbose/usingcurl-writeout
[minimon]: https://github.com/perryflynn/minimon
[bell]: https://en.wikipedia.org/wiki/Bell_character

## HTTP Verbindungen testen

Das folgende Beispiel ruft einfach die angegebene URL auf
und zeigt dessen Inhalt an:

```sh
curl -L -k https://example.com
```

Der Inhalt ist bei einem Verbindungstest meist aber
nicht von Interesse. Mit dem Parameter `-w` (`--write-out`)
kann `curl` verschiedene Zusatzinformationen ausgeben.

Das folgende Beispiel gibt Laufzeit, HTTP Status Code und Anzahl
der getätigten Verbindungen aus.

Außerdem wird der Exit Code von `curl` angehängt. Verläuft der
Verbindungsaufbau ohne Probleme, ist der Exit Code immer `0`.

Der Inhalt der Website wird unterdrückt.

```sh
( curl --silent --max-time 5 -k -L --max-redirs 32 \
    -w "\n%{time_total}\t%{http_code}\t%{num_connects}\t" \
    https://example.com; echo $? ) | tail -n 1
```

```txt
0,182852    200    2    0
```

- [curl Exit Codes][exit]
- [curl Writeout Variablen][writeout]

## TCP Verbindungen testen

Generische TCP Verbindungen zu testen ist ein bisschen hacky. Es gibt
keine verlässliche Möglichkeit nach dem Aufbau einer Verbindung diese
sofort wieder zu schließen, auch sind die Exit Codes nicht wirklich
aussagekräftig.

Abhilfe schafft das Aktivieren des Verbose Modes.

```sh
curl -v telnet://example.com:22
```

```txt
* Rebuilt URL to: telnet://localhost:22/
*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 22 (#0)
```

Findet sich in der Ausgabe die Zeile `* Connected to ...` war der
Verbindungsaufbau erfolgreich. `curl` kann nun mit `Ctrl+C` beendet
werden.

Folgendes Schnipsel macht dies automatisch mit Hilfe von `timeout`
und gibt `0` (Erfolg) oder `1` (Fehler) aus.

```sh
echo "$(timeout 1 curl -v telnet://example.com:22 2>&1)" | \
    grep -F "* Connected to " > /dev/null; echo $?
```

## Yet another project: Minimon

[Minimon][minimon] ist ein Bash Script welches all dies automatisiert,
und das Monitoring via HTTP, TCP und ICMP (Ping) ermöglicht, ohne eine
"echte" Monitoring Lösung installieren zu müssen. Perfekt für Wartungsarbeiten
und Debugging.

Funktioniert mit git Bash (MINGW), WSL und natürlich auch Linux.

```sh
./minimon.sh --interval 60 \
    --http "https://example.com" \
    --http "https://google.com;google" \
    --icmp "8.8.8.8;google" \
    --tcp "8.8.8.8:53"
```

```txt
[2020-11-07T00:50:12+01:00] http - https://example.com - OK (0) - HTTP 200
[2020-11-07T00:50:13+01:00] http_google - https://google.com - OK (0) - HTTP 200
[2020-11-07T00:50:14+01:00] tcp - 8.8.8.8:53 - OK (0) - Connect successful
[2020-11-07T00:50:17+01:00] icmp_google - 8.8.8.8 - OK (0) - Ping succeeded (0% loss)
```

Den einzelnen Verbindungen können benannt werden, sobald sich
der Status eines Tests verändert, gibt das Script eine neue Zeile aus
und löst die [ASCII Bell][bell] aus.
