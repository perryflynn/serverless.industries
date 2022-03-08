---
author: christian
title: '.NET Core Session Cookie Lifetime'
lang: en
ref: net-core-session-cookie-lifetime
tags: [ csharp, dotnet ]
---

The [.NET Core Session Store][sessions] allows it to store data server-side
for the current client. Per default the cookie which identifies the client only
remains in the browser until it's closed.

[sessions]: https://docs.microsoft.com/en-us/aspnet/core/fundamentals/app-state?view=aspnetcore-6.0
[cookiepolicy]: https://docs.microsoft.com/en-us/aspnet/core/security/gdpr?view=aspnetcore-6.0
[dataprotect]: https://docs.microsoft.com/en-us/aspnet/core/security/data-protection/configuration/overview?view=aspnetcore-6.0
[cache]: https://docs.microsoft.com/en-us/dotnet/api/microsoft.extensions.caching.distributed.idistributedcache?view=dotnet-plat-ext-6.0

Trying to change that results in the following error message:

> An exception of type 'System.InvalidOperationException' occurred in 
> Microsoft.AspNetCore.Session.dll but was not handled in user code: 
> 'Expiration cannot be set for the cookie defined by SessionOptions'

As a workaround we can use the [Cookie Policies][cookiepolicy], which are normally used to implement
the european privacy policy. It includes a callback to override the expiration time of the cookie.

One another problem appears when the application is deployed as a docker container. The session 
got resetted after each release, since the machine key is changing.

The [Data Protection Module][dataprotect] should be used to store these key in a textfile,
which can be stored outside of the container.

The full code example:

```cs
// Define key directory to keep the machine key the same
// when the docker container gets redeployed
var keyDir = new DirectoryInfo(builder.Configuration["AppKeyPath"]);
keyDir.Create();

services
    .AddDataProtection()
    .SetApplicationName("shouti")
    .PersistKeysToFileSystem(keyDir);

// Store session values into MongoDB
services.Add(ServiceDescriptor.Singleton<IDistributedCache, MongoDbCache>());
services.AddMemoryCache();

// Enable sessions, keep data for 14 days
services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromDays(14);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = false;
});

// Change cookie expiration from "until browser close" to 14 days
services.AddCookiePolicy(opts => {
    opts.CheckConsentNeeded = ctx => false;
    opts.OnAppendCookie = ctx => {
        ctx.CookieOptions.Expires = DateTimeOffset.UtcNow.AddDays(14);
    };
});

app.UseCookiePolicy();
app.UseSession();
```

The Sessions can be saved in any location. In my case it's a MongoDB database.
The only thing needs to be done is to implement the  [IDistributedCache Interface][cache]
and register the class as a service.

```cs
public class MongoDbCache : IDistributedCache
{
    private IDatabaseContextService context;

    private DTO.ISessionStorageSettings settings;

    private DateTime lastCleanup = DateTime.MinValue;

    public MongoDbCache(IDatabaseContextService context, DTO.ISessionStorageSettings settings)
    {
        this.context = context;
        this.settings = settings;
    }

    public byte[]? Get(string key)
    {
        var task = this.GetAsync(key);
        task.Wait();
        return task.Result;
    }

    public async Task<byte[]?> GetAsync(string key, CancellationToken token = default)
    {
        await this.EnsureCleanup();
        var item = (await this.context.Sessions.FindAsync(v => v.Key == key, null, token)).SingleOrDefault();

        if (item != null && (await this.IsExpired(item)) == false)
        {
            return item.Value;
        }

        return null;
    }

    public void Refresh(string key)
    {
        this.RefreshAsync(key).Wait();
    }

    public async Task RefreshAsync(string key, CancellationToken token = default)
    {
        await this.EnsureCleanup();

        var opts = new ReplaceOptions() { IsUpsert = true };
        var item = (await this.context.Sessions.FindAsync(v => v.Key == key, null, token)).SingleOrDefault();

        if(item != null)
        {
            item.ExpiresAt = DateTimeOffset.UtcNow.Add(this.settings.ExpiresAfter);
            await this.context.Sessions.ReplaceOneAsync(v => v.Key == key, item, opts, token);
        }
    }

    public void Remove(string key)
    {
        this.RemoveAsync(key).Wait();
    }

    public async Task RemoveAsync(string key, CancellationToken token = default)
    {
        await this.EnsureCleanup();
        await this.context.Sessions.DeleteOneAsync(v => v.Key == key, token);
    }

    public void Set(string key, byte[] value, DistributedCacheEntryOptions options)
    {
        this.SetAsync(key, value).Wait();
    }

    public async Task SetAsync(string key, byte[] value, DistributedCacheEntryOptions options, CancellationToken token = default)
    {
        await this.EnsureCleanup();

        var opts = new ReplaceOptions() { IsUpsert = true };
        var item = new DTO.Session()
        {
            Key = key,
            Value = value,
            ExpiresAt = DateTimeOffset.UtcNow.Add(this.settings.ExpiresAfter),
        };

        await this.context.Sessions.ReplaceOneAsync(v => v.Key == key, item, opts, token);
    }

    private async Task<bool> IsExpired(DTO.Session session, bool delete = true)
    {
        if (session.ExpiresAt < DateTimeOffset.Now)
        {
            if (delete)
            {
                await this.context.Sessions.DeleteOneAsync(v => v.Key == session.Key);
            }
            return true;
        }

        return false;
    }

    private async Task EnsureCleanup()
    {
        if (this.lastCleanup < DateTime.Now - this.settings.CleanupInterval)
        {
            var maxAge = DateTimeOffset.Now - this.settings.ExpiresAfter;
            var items = await this.context.Sessions.FindAsync(v => v.ExpiresAt < maxAge);
            var itemKeys = (await items.ToListAsync()).Select(v => v.Key).ToArray();

            await this.context.Sessions.DeleteManyAsync(v => itemKeys.Contains(v.Key));
            this.lastCleanup = DateTime.Now;
        }
    }
}
```
