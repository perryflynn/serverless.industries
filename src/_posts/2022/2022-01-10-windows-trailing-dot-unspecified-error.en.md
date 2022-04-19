---
author: christian
title: 'Error 0x80004005: Unspecified error'
locale: en
ref: windows-file-trailing-dot
tags: [ windows, 'continuous integration', gitlab ]
---

We tried to deploy a [Docusaurus][docu] website to a windows
system and used [chef-client][chef] to copy the HTML files
from GitLab Artifacts into the Windows Server folder.

[chef]: https://docs.chef.io/chef_client_overview/
[docu]: https://docusaurus.io/

When deploying the second time, all existing files will be removed and
the following error occures:

> Error 0x80004005: Unspecified error

That error came from a folder inside of the website data 
with **a trailing dot** in the name.

It is not possible to open the folder either:

> C:\Temp\foo\release-7.21.1015.6. is unavailable. If the location is on this PC,
> make sure the device or drive is connected or the disc is inserted, and then try again.

Usually it is not possible to create files or folders with a trailing
dot at all. But the `archive_file` chef resource did it somehow.

The file can be deleted with a CMD window and the following command:

```sh
rd /s /q "\\?\C:\Temp\foo\release-7.21.1015.6."
```

Source: [https://stackoverflow.com/a/4123152](https://stackoverflow.com/a/4123152)
