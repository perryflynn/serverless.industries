---
author: christian
title: minimon
projecttype: script
projecturl: https://github.com/perryflynn/minimon
ref: minimon
---

A small bash script compatible with Linux and Git Bash on windows
to monitor services and systems by http, tcp, icmp and custom scripts.

Uses bash jobs for parallelization and supports loading checks from
a JSON file. Tools like `bc` or `jq` will only be used if installed
to ensure a high compatibility.

```txt
[2020-11-04T23:44:13+01:00] http - https://example.com - OK (0) - HTTP 200
[2020-11-04T23:44:14+01:00] tcp - localhost:22 - NOK (2) - Connect failed
[2020-11-04T23:44:14+01:00] icmp_google - 8.8.8.8 - OK (0) - Ping succeeded (0% loss)
[2020-11-04T23:45:17+01:00] tcp - localhost:22 - OK (0) - Connect successful - changed after 63s
```
