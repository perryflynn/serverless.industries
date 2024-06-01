---
author: christian
title: minimon
projecttype: script
projecturl: https://github.com/perryflynn/minimon
projecttag: projects:minimon
image: assets/minimon-icon.png
ref: minimon
---

A small bash script compatible with Linux and Git Bash on windows
to monitor services and systems by http, tcp, icmp and custom scripts.

Uses bash jobs for parallelization and supports loading checks from
a JSON file. Tools like `bc` or `jq` will only be used if installed
to ensure a high compatibility.
