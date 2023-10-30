---
author: christian
title: Static Binaries
locale: en
ref: static-binaries
tags: [ linux, server, shell, debugging ]
---

While debugging issues in container environments or on embedded devices, there is always the
same problem: All the debugging tools are not installed.

Installing tools is often not an option, especially in environments where there is no internet
connection for security reasons.

An alternative can be static builds of these software tools. When a program is compiled static,
it contains all depencencies in one single program file and just works after copying the
program file.

A disadvantage is the file size. A static compiled `dig` is around 6 megabytes large, the
version from the package managers just 200 Kilobytes.

[files]: https://files.serverless.industries/bin/
[info]: https://files.serverless.industries/bin/info.txt
[qemu]: https://github.com/multiarch/qemu-user-static
[code]: https://github.com/perryflynn/static-binaries

## Downloads

The static binaries can be downloaded here: [https://files.serverless.industries/bin/][files]

Supported CPU architectures: `x86` (`i386`), `x86_64` (`amd64`), `ARM32v7` (`armv7`), `ARM64v8` (`aarch64`)

Supported Tools: `busybox`, `curl`, `dig`, `iperf2`, `iperf3`, `jq`, `rsync`, `scp`, `sftp`, 
`ssh-keygen`, `ssh-keyscan`, `ssh`, `tcpdump`, `vim`

More details can be found in the [info.txt][info] file.

## Build Scripts

The builds are done in my personal Gitlab instance with CI pipelines and Docker containers.
Other CPU architectures are build with the help of [multiarch/qemu-user-static][qemu].

The build process creates a base image for each CPU architecture which includes all
necessary tools to build the program, builds the programs for each CPU architecture
and [uploads them][files].

A mirror of the build code can be found on [my GitHub Account][code].
