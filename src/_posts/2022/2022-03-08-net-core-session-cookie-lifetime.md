---
author: christian
title: '.NET Core Session Cookie Lifetime'
lang: de
ref: net-core-session-cookie-lifetime
tags: [ csharp, dotnet ]
---

Der [.NET Core Session Store][sessions] erlaubt es für den aktuellen Client
serverseitig Daten zu speichern. Das Cookie welches den Browser identifiziert
lässt sich normalerweise nur so lange im Browser speichern, bis dieser geschlossen wird.

[sessions]: https://docs.microsoft.com/en-us/aspnet/core/fundamentals/app-state?view=aspnetcore-6.0
[cookiepolicy]: https://docs.microsoft.com/en-us/aspnet/core/security/gdpr?view=aspnetcore-6.0
[dataprotect]: https://docs.microsoft.com/en-us/aspnet/core/security/data-protection/configuration/overview?view=aspnetcore-6.0
[cache]: https://docs.microsoft.com/en-us/dotnet/api/microsoft.extensions.caching.distributed.idistributedcache?view=dotnet-plat-ext-6.0

Versucht man dies zu ändern, erhält man folgende Fehlermeldung:

> An exception of type 'System.InvalidOperationException' occurred in 
> Microsoft.AspNetCore.Session.dll but was not handled in user code: 
> 'Expiration cannot be set for the cookie defined by SessionOptions'

Über die [Cookie Policies][cookiepolicy], welche eigentlich zur Umsetzung der Datenschutzgrundverordnung
dienen, kann man die Ablaufzeit des Cookies aber dennoch verändern.

Ein weiteres Problem kommt zum Vorschein, wenn die Anwendung in einem Docker Container
deployed wird. Die Sessions werden neu gestartet bei jedem Release. Das liegt
daran, dass sich jedes mal der Machine Key ändert, mit dem die Session Daten verschlüsselt
werden.

Mit dem [Data Protection Modul][dataprotect] können die Keys in einer Textdatei gespeichert
werden und bleiben somit gleich, wenn die Keys in einem Volume abgelegt werden.

Der komplette Code:

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

Die Sessions können in jedem beliebigen Ort gespeichert werden. In meinem Beispiel ist
es eine MongoDB Datenbank. Es muss nur das [IDistributedCache Interface][cache] implementiert
und die Klasse als Service registriert werden.

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
