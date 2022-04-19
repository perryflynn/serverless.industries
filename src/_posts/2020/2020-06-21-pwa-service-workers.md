---
author: christian
title: "Progressive Web Apps und Service Workers"
locale: de
ref: pwa-service-workers
tags: ['javascript', 'html', 'projects']
image: /assets/serverless-pwa.png
---

Eine Progressive Web App (PWA) ist eine Website, welche sich wie
eine APP auf einem PC oder Smartphone installieren lässt.
Ein Service Worker schaltet sich als Proxy zwischen HTTP Requests
und den Webserver.

![serverless.industries PWA]({{'/assets/serverless-pwa.png' | relative_url}}){:.img-fluid}

Mit in Java Script geschriebenen Regelwerken
kann im Service Worker entschieden werden, welche
Anfragen von **einem Cache** beantwortet werden können
und welche an den Webserver weitergeleitet werden.

Eine Website kann also **komplett offline verfügbar gemacht werden**.
Eingegebene Daten können im [Local Storage][ls] oder in der
[IndexedDB][idb] zwischengespeichert werden und sobald wieder eine
Internet Verbindung besteht, an den Server gesendet werden.

[ls]: https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage
[idb]: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API

## Website Manifest

Mit der Datei `site.webmanifest` werden Dinge die Name, Startseite,
App Icons und Farben definiert, welche später für das Installieren
als App benötigt wird.

```json
{
    "name": "serverless.industries",
    "short_name": "serverless.industries",
    "start_url": "https://serverless.industries/index.html",
    "icons": [
        {
            "src": "/favicon/android-chrome-192x192.png",
            "sizes": "192x192",
            "type": "image/png"
        },
        {
            "src": "/favicon/android-chrome-384x384.png",
            "sizes": "384x384",
            "type": "image/png"
        }
    ],
    "theme_color": "#ffffff",
    "background_color": "#ffffff",
    "display": "standalone"
}
```

Die Datei muss mit einem `<meta>` Tag referenziert werden:

```html
<link rel="manifest" href="/site.webmanifest">
```

## Service Worker

Der Service Worker regelt wie gesagt die Kommunikation mit dem Webserver,
erstellt einen Cache und erledigt die Fehlerbehandlung, falls keine
Internetverbindung besteht.

![Service Worker Info]({{'/assets/service-worker-info.png' | relative_url}}){:.img-fluid}
![Service Worker Cache]({{'/assets/service-worker-cache.png' | relative_url}}){:.img-fluid}

Eine `service-worker.js` Datei kann wie folgt aussehen:

```js
const cacheKey = 'site-cache-v1';
const basePath = 'https://example.com/';

// list of ressources to cache
const forceCacheList = [
    // pages
    'index.html',
    'offline.html',
    'site.webmanifest',

    // assets
    'css/main.css',
    'favicon/apple-touch-icon.png',
    'favicon/favicon-32x32.png',
    'favicon/favicon-16x16.png',
    'favicon/safari-pinned-tab.svg',
    'favicon/android-chrome-192x192.png',
]
.map(url => basePath + url);

// cache one url
const cacheOne = async (url, response) =>
{
    var cache = await caches.open(cacheKey);
    await cache.put(url, response.clone());
};

// perform a cache update
const performUpdate = async () =>
{
    // update assets
    await Promise.all(forceCacheList.map(async url =>
    {
        const cacheResponse = await fetch(url + '?' + ts)
        await cacheOne(url, cacheResponse);
    }));
};

// create cache
performUpdate();

// listen for requests for page assets and serve from cache
const failedRequestHandler = err =>
{
    return caches.match(basePath + 'offline.html');
}

// listen for requests
self.addEventListener('fetch', event =>
{
    // only for GET requests from our page
    if (event.request.method === 'GET' &&
        event.request.url.startsWith(basePath))
    {
        const cacheHandler = caches.match(event.request.url).then(cacheItem =>
        {
            // cache first
            return cacheItem || fetch(event.request.url)
                .catch(failedRequestHandler);
        });

        event.respondWith(cacheHandler);
    }
});
```

Alle in der Liste befindlichen Dateien werden beim Start des
Service Workers im Cache abgelegt. Alle Anfragen an diese
Dateien werden anschließend vom Service Worker und dem
Cache beantwortet.

Alle anderen Dateien werden, wenn das Gerät offline ist,
mit der Datei `offline.html` beantwortet. Für weitere Informationen
empfehle ich den [Introduction to Service Worker][intro]
Artikel von Google.

[intro]: https://developers.google.com/web/ilt/pwa/introduction-to-service-worker

Nun muss der Service Worker noch mit ein wenig Java Script
im Code der Website registriert werden:

```js
if ('serviceWorker' in navigator)
{
    navigator.serviceWorker
        .register('/service-worker.js')
        .then(reg => console.log('Service Worker registered with scope:', reg.scope))
        .catch(err => console.log('Service Worker registration failed: ', err));
}
```

## Cached, und nun?

Jetzt wird es aber erst richtig kompliziert. Was tun, wenn die
Website offline gecached ist und es Updates gibt? Was tun,
wenn es für den Service Worker selbst updates gibt?

Das hängt stark von der Website ab. Für serverless.industries
habe ich es mir leicht gemacht:

- Bei jedem Build der Seite eine `lastUpdate.txt` Datei erzeugen
  und den aktuellen Unix Timestamp reinschreiben
- Die Datei im Service Worker Cache ablegen, wenn nicht vorhanden
- Bei jedem Aufruf der Seite die Datei vom Server abrufen
  und mit dem Cache vergleichen

Wenn Server Timestamp größer als lokaler Timestamp:

- Service Worker aktualisieren und neu starten
- Cache neu herunterladen
- Website ggf. reloaden

Website und Service Worker kommunizieren dabei bidirektional über die
[Messaging API][msg]. Denn das Aktualisieren des Service Workers
muss natürlich von der Website ausgelöst werden. Der Cache
wird danach aber vom Service Worker aktualisiert.

Den [Source Code des Service Workers][siworker] und den
[Source Code des Update Prozesses][siinit] (in der `appLoad()` function)
gibt es im [Code Repository][sigit] dieses Projektes.

[sigit]: https://github.com/perryflynn/serverless.industries
[msg]: https://developer.mozilla.org/en-US/docs/Web/API/Client/postMessage
[siworker]: https://github.com/perryflynn/serverless.industries/blob/master/src/service-worker.js
[siinit]: https://github.com/perryflynn/serverless.industries/blob/master/src/_layouts/default.html
