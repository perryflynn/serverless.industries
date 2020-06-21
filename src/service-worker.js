---
# this ensures Jekyll reads the file to be transformed later
# only Main files contain this front matter, not partials.
---

console.log('Welcome to a service worker powered website');

const cacheKey = 'site-cache-v1';
const basePath = '{{site.url}}{{"/" | relative_url}}';

// list of ressources to cache
const forceCacheList = [
    // pages
    '', // index.html
    'index.html',
    'index.en.html',
    'offline.html',
    'authors.html',
    'tags.html',
    'site.webmanifest',

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

const cacheList = forceCacheList;


// listen for requests for page assets and serve from cache
const failedRequestHandler = err =>
{
    return caches.match(basePath + 'offline.html');
}

const cacheOne = async (url, response, event) =>
{
    var cache = await caches.open(cacheKey);
    await cache.put(url, response.clone());

    const client = await clients.get(event.source.id);
    if (client)
    {
        await client.postMessage({
            type: 'URL_CACHED',
            uid: url,
            result: true
        });
    }
};

self.addEventListener('fetch', event =>
{
    if (event.request.method === 'GET' &&
        event.request.url.startsWith(basePath))
    {
        const cacheHandler = caches.match(event.request.url).then(cacheItem =>
        {
            // cache first, request if cache not available
            // for files in the force cache list
            if (forceCacheList.includes(event.request.url))
            {
                // cache first
                return cacheItem || fetch(event.request.url)
                    .then(response =>
                    {
                        // add fetched ressource to cache
                        return cacheOne(event.request.url, response, event)
                            .then(() => response);
                    })
                    .catch(failedRequestHandler);
            }
            // request first, cache if request fails
            // for files in the extended cacheList
            else
            {
                // request first
                return fetch(event.request.url)
                    .then(response =>
                    {
                        // update cache if in extended cache list
                        if (cacheList.includes(event.request.url))
                        {
                            // add fetched ressource to cache
                            return cacheOne(event.request.url, response, event)
                                .then(() => response);
                        }

                        return response;
                    })
                    .catch(err => cacheItem || failedRequestHandler(err));
            }
        });

        event.respondWith(cacheHandler);
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
        const response = await fetch(basePath + 'lastUpdate.txt?' + ts);
        const remoteTimestamp = parseInt(await response.text());

        // get local state
        const cache = await caches.open(cacheKey);
        const cacheItem = await cache.match(checkUrl);

        let localTimestamp = -1;
        if (cacheItem)
        {
            localTimestamp = parseInt(await cacheItem.clone().text());
        }

        if (localTimestamp < 0)
        {
            // no local cache available
            return 1;
        }
        else if (localTimestamp < remoteTimestamp)
        {
            // local cache expired
            return 2;
        }
        else
        {
            // no updates
            return 0;
        }
    }
    catch
    {
        return false;
    }
};


// perform a cache update
const performUpdate = async (event) =>
{
    const ts = Date.now();
    const checkUrl = basePath + 'lastUpdate.txt';

    // update state file
    const checkResponse = await fetch(checkUrl + '?' + ts);
    await cacheOne(checkUrl, checkResponse, event);

    // update assets
    await Promise.all(cacheList.map(async url =>
    {
        const cacheResponse = await fetch(url + '?' + ts)
        await cacheOne(url, cacheResponse, event);
    }));
};


// listen for messages from frontend
const messageRespond = async (event, result) =>
{
    const client = await clients.get(event.source.id);

    if (client)
    {
        client.postMessage({
            type: event.data.type + '_RESULT',
            uid: event.data.uid,
            result: result
        });
    }
};


// listen for event from frontend
self.addEventListener('message', async event =>
{
    // check if a ressource is cached
    if (event.data.type === 'CHECK_OFFLINE_STATE' && event.data.uid)
    {
        var cacheItem = await caches.match(event.data.uid);
        await messageRespond(event, !!cacheItem);
    }
    // request to add a url to cache
    else if(event.data.type === 'ADD_CACHE_URL' && event.data.uid)
    {
        try
        {
            await cacheOne(event.data.uid, await fetch(event.data.uid), event);
            await messageRespond(event, true);
        }
        catch
        {
            await messageRespond(event, false);
        }
    }
    // request to remove url from cache
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
    // check if updates available on server
    else if(event.data.type === 'CHECK_UPDATES')
    {
        const result = await checkUpdates();
        await messageRespond(event, result);
    }
    // perform cache refresh
    else if(event.data.type === 'UPDATE_CACHE')
    {
        await performUpdate(event);
        await messageRespond(event, true);
    }
});
