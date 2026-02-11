---
author: christian
title: "YotLD: MakeMKV on Linux"
locale: en
tags: [ linux, debian ]
image: /assets/yotld.jpg
series:
  tag: series:yearofthelinuxdesktop
  index: 2
---

[MakeMKV](https://www.makemkv.com/) is a great tool to bring BluRay movies you own into [JellyFin][jf]. 
For some reason, it is required [to build the Linux version][mkvl] of MakeMKV. There is no prebuild 
package available from the original developers.

[mkvl]: https://forum.makemkv.com/forum/viewtopic.php?f=3&t=224&sid=03206c5b0b00457a75567ead92a1c98e
[jf]: https://jellyfin.org/

I try to not mess up my Linux filesystem if possible, so I created a Dockerfile to build
MakeMKV with podman.

**tl;dr:** The code can be found [on my codeberg](https://codeberg.org/pery/laptop).

MakeMKV comes with two packages:

- Closed source `makemkv-bin` package
- Open source `makemkv-oss` package

Of course there are more dependencies to be build:

- `ffmpeg` in the latest version
- `fdk-aac`

The script [build-makemkv.sh][buildmkv] executes podman to download source packages and build all 
components. Inside of the resulting docker image, the working MakeMKV can be found 
in `/opt/makemkv`.

This folder is extracted from the Docker image by launching a temporary container.
After that, it should be moved into `/opt/makemkv` on the host system and can be started like so:

```sh
LD_LIBRARY_PATH=/opt/makemkv/lib/ /opt/makemkv/bin/makemkv
```

You also may want to create a `MakeMKV.desktop` shortcut:

```ini
[Desktop Entry]
Comment[en_US]=
Comment=
Exec=env LD_LIBRARY_PATH=/opt/makemkv/lib/ /opt/makemkv/bin/makemkv
GenericName[en_US]=
GenericName=
Icon=/opt/makemkv/share/icons/hicolor/128x128/apps/makemkv.png
MimeType=
Name[en_US]=MakeMKV
Name=MakeMKV
Path=
PrefersNonDefaultGPU=false
StartupNotify=true
Terminal=false
TerminalOptions=
Type=Application
X-KDE-SubstituteUID=false
X-KDE-Username=
```

Have fun!

[buildmkv]: https://codeberg.org/pery/laptop/src/branch/master/build/makemkv/build-makemkv.sh
