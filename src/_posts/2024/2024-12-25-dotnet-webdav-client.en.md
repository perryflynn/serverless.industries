---
author: christian
title: Implementing a WebDAV Client in .NET
locale: en
tags: [ csharp, software development, web service, webdav, http ]
---

In a project I had to download files from a Nextcloud. I decided to use WebDAV, as it also allows 
to switch to another file cloud solution in the future.

I didn't found a nice WebDAV package on NuGET, so I decided to implement the WebDAV by myself. 
And honestly? It is really no big deal.

**tl;dr**: The C# code can be found on [my GitHub](https://github.com/perryflynn/perrys-webdav-client).

## Basic Usage

It's just a single HTTP Request where the URL decides which file or folder is queried. Downloading a 
file with a `GET` request just works. If a folder content should be listed, the not so usual 
`PROPFIND` request has to be used.

propfind.txt:

```xml
<?xml version="1.0"?>
<d:propfind xmlns:d="DAV:">
    <d:prop>
        <d:resourcetype/>
        <d:getlastmodified/>
        <d:getcontentlength/>
        <d:getcontenttype/>
        <d:resourcetype/>
        <d:getetag/>
    </d:prop>
</d:propfind>
```

Depending on the WebDAV Server, there are different elements supported in the `<d:prop>` list. 
This list was made using the [Nextcloud documentation][nextdoc].

[nextdoc]: https://docs.nextcloud.com/server/19/developer_manual/client_apis/WebDAV/basic.html

Request:

```sh
curl -v \
    --user user:apppassword \
    -X PROPFIND \
    -H "Depth: 1"
    --data @propfind.txt \
    "https://cloud.example.com/remote.php/dav/files/user/"
```

Simplified Response:

```xml
<?xml version="1.0"?>
<d:multistatus>
    <d:response>
        <d:href>/remote.php/dav/files/test2.png</d:href>
        <d:propstat>
            <d:prop>
                <d:resourcetype/>
                <d:getlastmodified>Thu, 01 Jun 2023 08:56:36 GMT</d:getlastmodified>
                <d:getcontentlength>300234</d:getcontentlength>
                <d:getcontenttype>image/png</d:getcontenttype>
                <d:getetag>&quot;33cc1e16c5b589e9476e7ff81a7bcacc&quot;</d:getetag>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
        </d:propstat>
    </d:response>
</d:multistatus>
```

The list contains all files and folders. The `Depth` header controls how many levels should 
be included in the response. 

## Bonus: Check if file was modified

When the files are cached somewhere in the .NET application, it is maybe interesting to check if
the original file was changed. Depending on the WebDAV Server, this is possible by using
the [ETag/If-None-Match mechanic][etag]:

```sh
curl -v \
    --user user:apppassword \
    -H "If-None-Match: \"4b1f2c01dda174d60dfdc2d203d78c1a\"" \
    "https://cloud.example.com/remote.php/dav/files/user/test2.png"
```

Every  `GET`/`HEAD` request returns an `ETag` header, which contains the checksum for the 
requested resource. This has to be stored somehow in the .NET application. As soon as a check 
if the file was modified must be done, the request above can be sent.

If the file was modified, the server will return the content of that file. If not, the server 
will respond with a status `304 Not Modified` with no body.

[etag]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match

## The Code

[https://github.com/perryflynn/perrys-webdav-client](https://github.com/perryflynn/perrys-webdav-client)
