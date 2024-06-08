---
author: christian
title: Unifi Controller Upgraded to 8.0.28
locale: en
tags: [ debian, apt, unifi, network, projects, projects:packagerepos ]
---

I've updated my [Unifi packages for Debian 12 "Bookworm"]({% post_url 2023/2023-08-10-unifi-debian-bookworm %})
to version 8.0.28. [Aparently][apa1] it supports now finally MongoDB 4.4 out of the box, without hack and repack
the Debian package.

Version 8.2 even [supports MongoDB 7.0][apa2] as it looks like, but there are too many Bug Report
comments on the release page, so I'll wait a little bit more.

So maybe next time I post an update my repo becomes finally obsolete. 🚀

[apa1]: https://community.ui.com/releases/UniFi-Network-Application-8-0-28/f7492865-778d-4539-aaf8-3fb09c4279b0
[apa2]: https://community.ui.com/releases/UniFi-Network-Application-8-2-93/fce86dc6-897a-4944-9c53-1eec7e37e738

My current setup:

- OS: Debian 12 "Bookworm"
- Upgraded mongodb-org-server from `4.4.24` to `4.4.29`
- Removed openjdk-11-jre-headless
- Installed openjdk-17-jre-headless
- Upgraded unifi from `7.4.162-21057-1+unlocked` to `8.0.28-24416-1+unlocked`

There is also now [a guide with detailed infos about the repo]({% post_url guides/2024-06-08-package-repositories %}).
