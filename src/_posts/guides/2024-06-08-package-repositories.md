---
author: christian
title: "APT Repositories: Components and Package Versions"
locale: en
shortlink: packages
tags: [ debian, apt, projects, projects:packagerepos ]
excerpt_separator: <!--more-->
changelog:
  - timestamp: 2024-06-08
    comment: Published
---

Some time ago I started to host my own APT repository for Unifi and MongoDB packages,
as the software quality of Unifi is really bad and it prevented me from upgrade the
Debian version to the latest stable release.

This guide shows the current status of the repository and which packages are available.


<!--more-->


## Repository

URL: [https://files.serverless.industries/apt/repo/](https://files.serverless.industries/apt/repo/)  
GnuPG Key: [https://files.serverless.industries/apt/serverless-packages.asc](https://files.serverless.industries/apt/serverless-packages.asc)

Distribution: `hopefullystable` (I use these packages by myself, but the name is meant seriously.
No guarantee that these packages really work as you may think.)

The repo is updated manually. **There is no focus on fast bugfixes or security.**

Last update: 2024-06-08

## Components

The packages use differnet components to control very easily which ones shall be used.
Currently I use mainly the combination of `mongodb44` and `unifi`.

Example usage for installing a Unifi Controller with MongoDB 4.4: 

```txt
deb [signed-by=/usr/share/keyrings/serverless-packages.gpg] https://files.serverless.industries/apt/repo hopefullystable mongodb44 unifi
```

### mongodb44

Mirror of `deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main`.

Tested on Debian 12 "Bookworm".

- `mongodb-org-database-tools-extra`: many 4.4.x, latest is 4.4.29
- `mongodb-org-mongos`: many 4.4.x, latest is 4.4.29
- `mongodb-org-server`: many 4.4.x, latest is 4.4.29
- `mongodb-org-shell`: many 4.4.x, latest is 4.4.29
- `mongodb-org-tools`: many 4.4.x, latest is 4.4.29

### mongodb50

Mirror of `deb http://repo.mongodb.org/apt/debian bullseye/mongodb-org/5.0 main`.

Currently not used. Happy to get some feedback if it works.

- `mongodb-org-database`: many 5.0.x, latest is 5.0.27
- `mongodb-org-database-tools-extra`: many 5.0.x, latest is 5.0.27
- `mongodb-org-mongos`: many 5.0.x, latest is 5.0.27
- `mongodb-org-server`: many 5.0.x, latest is 5.0.27
- `mongodb-org-shell`: many 5.0.x, latest is 5.0.27
- `mongodb-org-tools`: many 5.0.x, latest is 5.0.27

### unifi

Manual selection of releases of the Unifi Controller with removed MongoDB version restriction
to make it work on stable Debian releases and newer MongoDB versions. This uses a fork of 
[unifi-repack by Julien Lecomte][repack].

[repack]: https://gitlab.com/jlecomte/unifi-repack

Packages partially mirrored from the official mirror and manually downloaded from the 
[Unifi Release Page](https://community.ui.com/releases) (search for "UniFi Network Application").

Tested on all Debian releases including Debian 12 "Bookworm".

- `unifi`: 
    - `8.0.28-24416-1+unlocked` 
    - `7.5.187-22891-1+unlocked`, `7.4.162-21057-1+unlocked`
    - `7.3.83-19645-1+unlocked`
    - `7.2.97-18705-1+unlocked`
    - `7.1.68-17885-1+unlocked` 
    - `7.0.25-17292-1+unlocked`
    - `6.5.55-16678-1+unlocked`, `6.5.54-16676-1+unlocked`
    - `6.4.54-16067-1+unlocked`
    - `5.14.23-13880-1+unlocked`
    - `5.6.42-10376-1+unlocked`, `5.6.40-10370-1+unlocked`
