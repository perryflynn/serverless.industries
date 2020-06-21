---
# this ensures Jekyll reads the file to be transformed later
# only Main files contain this front matter, not partials.
---

const cacheKey = 'site-cache-v1';
const cacheUrlExtension = 'dev'; // '{{site.time | date: "%s%N"}}';
const basePath = '{{site.url}}{{"/" | relative_url}}';

const forceCacheList = [
    // assets
    'css/Datacenter_Empty_Floor-snip.jpg',
    'css/cc-80x15.png',
    'js/jquery-3.5.1.slim.min.js',
    'js/bootstrap.bundle.min.js',
    'css/main.css',
    'css/webfonts/fa-solid-900.woff2',
    'css/webfonts/fa-brands-400.woff2',
    'css/webfonts/fa-regular-400.woff2',
    'css/webfonts/fa-solid-900.woff',
    'css/webfonts/fa-brands-400.woff',
    'css/webfonts/fa-regular-400.woff',
    'css/webfonts/fa-solid-900.ttf',
    'css/webfonts/fa-brands-400.ttf',
    'css/webfonts/fa-regular-400.ttf',

    // favicons
    'favicon/apple-touch-icon.png',
    'favicon/favicon-32x32.png',
    'favicon/favicon-16x16.png',
    'favicon/safari-pinned-tab.svg',
    'favicon/android-chrome-192x192.png',
]
.map(url => basePath + url);

const cacheList = [
    ... forceCacheList,

    ... [
        // pages
        '', // index.html
        'index.html',
        'index.en.html',
        'offline.html',
        'authors.html',
        'tags.html',
        'site.webmanifest',
    ]
    .map(url => basePath + url)
];

// listen for requests for page assets and serve from cache
const failedRequestHandler = err =>
{
    return caches.match(basePath + 'offline.html');
}

self.addEventListener('fetch', event =>
{
    if (event.request.method === 'GET' &&
        event.request.url.startsWith(basePath))
    {
        const cacheHandler = caches.match(event.request).then(cacheItem =>
        {
            if (forceCacheList.includes(event.request.url))
            {
                // cache first
                return cacheItem || fetch(event.request.url)
                    .catch(failedRequestHandler);
            }
            else
            {
                // request first
                return fetch(event.request.url)
                    .then(response =>
                    {
                        // update cache if in extended cache list
                        if (cacheList.includes(event.request.url))
                        {
                            return caches.open(cacheKey)
                                .then(cache =>
                                {
                                    cache.put(event.request.url, response.clone());
                                    return response;
                                });
                        }

                        return response;
                    })
                    .catch(err => cacheItem || failedRequestHandler(err));
            }
        });

        event.respondWith(cacheHandler);
    }
    else
    {
        console.log('not processed:', event.request, basePath);
    }
});

// check updates mechanism
const checkUpdates = async () =>
{
    try
    {
        // get remote status
        const ts = Date.now();
        const checkUrl = basePath + 'lastUpdate.txt';
        const response = await fetch(basePath + 'lastUpdate.txt?' + ts)
        const cacheReponse = response.clone();

        const remoteTimestamp = parseInt(await response.text());

        // get local state
        const cache = await caches.open(cacheKey);
        const cacheItem = await cache.match(checkUrl);

        let localTimestamp = -1;
        if (cacheItem)
        {
            localTimestamp = parseInt(await cacheItem.clone().text());
        }

        return localTimestamp < remoteTimestamp;
    }
    catch
    {
        return false;
    }
};

const performUpdate = async () =>
{
    const ts = Date.now();
    const cache = await caches.open(cacheKey);
    const checkUrl = basePath + 'lastUpdate.txt';

    // update assets
    cacheList.forEach(url =>
    {
        fetch(url + '?' + ts).then(urlResponse => cache.put(url, urlResponse));
    });

    // update state file
    fetch(checkUrl + '?' + ts).then(urlResponse => cache.put(checkUrl, urlResponse));
};

// listen for messages from frontend
const messageRespond = async (event, result) =>
{
    const client = await clients.get(event.source.id);

    client.postMessage({
        type: event.data.type + '_RESULT',
        uid: event.data.uid,
        result: result
    });
};

self.addEventListener('message', async event =>
{
    if (event.data.type === 'CHECK_OFFLINE_STATE' && event.data.uid)
    {
        var cacheItem = await caches.match(event.data.uid);
        await messageRespond(event, !!cacheItem);
    }
    else if(event.data.type === 'ADD_CACHE_URL' && event.data.uid)
    {
        const cache = await caches.open(cacheKey);

        try
        {
            await cache.put(event.data.uid, await fetch(event.data.uid));
            await messageRespond(event, true);
        }
        catch
        {
            await messageRespond(event, false);
        }
    }
    else if(event.data.type === 'REMOVE_CACHE_URL' && event.data.uid)
    {
        const cache = await caches.open(cacheKey);
        try
        {
            await cache.delete(event.data.uid);
            await messageRespond(event, true);
        }
        catch
        {
            await messageRespond(event, false);
        }
    }
    else if(event.data.type === 'CHECK_UPDATES')
    {
        const result = await checkUpdates();
        await messageRespond(event, result);
    }
    else if(event.data.type === 'UPDATE_CACHE')
    {
        await performUpdate();
        await messageRespond(event, true);
    }
});
