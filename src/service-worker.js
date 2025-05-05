---
# this ensures Jekyll reads the file to be transformed later
# only Main files contain this front matter, not partials.
---

const cacheKey = 'site-cache-v1';
const basePath = '{{site.url}}{{"/" | relative_url}}';
const commit = "{{site.git.commitlong}}";
const version = "{{site.git.commitlong}}_{{site.time | date: '%Y-%m-%d_%k-%M-%S'}}";

console.log('Service worker (re)started. Welcome to a service worker powered website (' + version + ')');

// list of ressources to cache
const forceCacheList = [
    // no cache killer parameter
    ... [
        '',
        'index/de/',
        'index/en/',
        'tag/',
        'guides/',
        'people/',
        'offline.html',
        'authors.html',
        'projects.html',
        'archive.html',
        'search.html'
    ]
    .map(url => basePath + url),

    // with cache killer parameter
    ... [
        'site.webmanifest',
        'search.json',

        // assets
        'css/Datacenter_Empty_Floor-snip.jpg',
        'css/cc-80x15.png',
        'js/jquery-3.7.1.slim.min.js',
        'js/bootstrap.bundle.min.js',
        'css/main.css',
        'css/icons.css',
        'css/webfonts/materialdesignicons-webfont.woff',
        'css/webfonts/materialdesignicons-webfont.woff2',
        'css/webfonts/materialdesignicons-webfont.ttf',
        'js/mermaid-10.9.1/mermaid.min.js',
        'js/search.js',

        // favicons
        'favicon/apple-touch-icon.png',
        'favicon/favicon-32x32.png',
        'favicon/favicon-16x16.png',
        'favicon/safari-pinned-tab.svg',
        'favicon/android-chrome-192x192.png',
    ]
    .map(url => basePath + url + '?commit=' + commit),
];

const cacheList = forceCacheList;


// listen for requests for page assets and serve from cache
const failedRequestHandler = err =>
{
    return caches.match(basePath + 'offline.html');
}

const clearCache = async () =>
{
    await caches.delete(cacheKey);
};

const cacheOne = async (url, response, event) =>
{
    var cache = await caches.open(cacheKey);
    await cache.put(url, response.clone());

    if (event.source && event.source.id)
    {
        const client = await clients.get(event.source.id);
        if (client)
        {
            await client.postMessage({
                type: 'URL_CACHED',
                uid: url,
                result: true
            });
        }
    }
};

self.addEventListener('fetch', event =>
{
    // start page redirect
    if (event.request.method === 'GET' &&
        (event.request.url == basePath || event.request.url.startsWith(basePath+'index.html')))
    {
        event.respondWith(new Response('', {
            status: 302,
            statusText: 'Found',
            headers: {
                Location: basePath + 'index/',
            }
        }));
    }
    // cache handling for blog pages
    else if (event.request.method === 'GET' &&
        event.request.url.startsWith(basePath))
    {
        const cacheHandler = caches.match(event.request.url).then(cacheItem =>
        {
            // cache first, request if cache not available
            // for files in the force cache list
            if (forceCacheList.includes(event.request.url))
            {
                // cache first
                return cacheItem || fetch(event.request.url, { mode: 'no-cors', redirect: 'manual' })
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
                return fetch(event.request.url, { mode: 'no-cors', redirect: 'manual' })
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
        const remoteSha = await response.text();

        // get local state
        const cache = await caches.open(cacheKey);
        const cacheItem = await cache.match(checkUrl);

        let localSha = null;
        if (cacheItem)
        {
            localSha = await cacheItem.clone().text();
        }

        if (localSha === null)
        {
            // no local cache available
            return 1;
        }
        else if (localSha !== remoteSha)
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
        // error
        return -1;
    }
};


// perform a cache update
const performUpdate = async (event) =>
{
    const ts = Date.now();
    const checkUrl = basePath + 'lastUpdate.txt';

    // clear
    await clearCache();

    // update state file
    const checkResponse = await fetch(checkUrl + '?' + ts);
    await cacheOne(checkUrl, checkResponse, event);

    // update assets
    await Promise.all(cacheList.map(async url =>
    {
        const cacheResponse = await fetch(url + (url.includes('?') ? '&' : '?') + 'anticache=' + ts)
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


// initialize application
self.addEventListener('install', async event =>
{
    console.log('Create asset cache...');
    event.waitUntil(performUpdate(event));
});


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
});
