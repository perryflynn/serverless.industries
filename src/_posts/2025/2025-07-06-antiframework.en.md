---
author: christian
title: "The Anti-Framework"
locale: de
tags: [ projects, php, 'software development' ]
---

After all these years, I still love PHP. Every time when I create a small or big personal 
project which should work for a long time with low effort, I choose PHP over .NET 
or Angular. It "just works".

But Frameworks are annoying.

Every major update overengineers some feature and brings new breaking changes, which are
sometimes very hard to figure out. When [silex][silex] got deprecated in 2018, I "lost" two
of my bigger projects.

[silex]: https://github.com/silexphp/Silex

Introducting my [Anti Framework](https://github.com/perryflynn/anti-framework).

This collection of classes will never be available as a composer package, it is meant to
be copied into a project directly.

## Dependency Injection

The dependency injection container allows it to inject class instances directly into
other classes or into method class and is mainly used together with the `HttpRouter` class.

```php
$container = new \PerrysFramework\DependencyInjection();

$context = new \PerrysFramework\DbContext();
$context->connect('localhost', 'dbname', 'user', 'pass');
$container->register(\PerrysFramework\DbContext::class, function() use($context) { return $context; });

class AwesomeClass
{
    public __construct(\PerrysFramework\DbContext $context)
    {
        // do stuff
    }
}

$instance = $container->newClassInstance('AwesomeClass');
```

The example is of course a little bit dumb, it only makes sense in 
complex setups with the `HttpRouter`.

## HTTP Router

The HTTP router directs a incoming request into a matching PHP function. It also supports 
middlewares and OpenAPI manifest generation.

Authorization can be implemented via middlewares as well.

```php
<?php

declare(strict_types=1);

$container = new \PerrysFramework\DependencyInjection();

// http router
$request = \PerrysFramework\HttpRequest::fromCurrentContext();
$container->register(get_class($request), function() use($request) { return  $request; });
$router = $container->newClassInstance(\PerrysFramework\HttpRouter::class);
$container->register(get_class($router), function() use($router) { return  $router; });

// OpenAPI
$router->add('swagger', 'GET', 'swagger-v1', function() use($router)
{
    $openapi = new \PerrysFramework\OpenAPI($router, \PerrysFramework\OpenApiTags::TagList);
    $openapi->setInfo('nice API', 'a very nice API', 'v1');
    return new \PerrysFramework\HttpJsonResponse(200, $openapi->generate());
});

// demo endpoint
$router->add('ping', 'GET', 'ping', function()
{
    return new \PerrysFramework\HttpResponse(200, 'pong', [ 'Content-Type' => 'text/plain' ]);
})
->setTag('Tests')
->setSummary('Ping?');

// launch
$router
    ->run($request)
    ->respond();
```

## Database Class

Besides of simple SQL queries, the database class also supports migration scripts, a registry-like
key-value store and convienience methods to easily insert/update/delete rows.

```php
$context = new \PerrysFramework\DbContext();
$context->connect('localhost', 'dbname', 'user', 'pass');
$context->migrate(__DIR__."/dbmigrations");

// query(), querySingle(), queryColumn() for simple SQL queries
// execute() for table changes

$context->insert('table', [ 'col1' => 'value', 'col2' => 'value2' ]);
$context->delete('table', [ 'col1' => 'value' ]);

$context->update('table', 
    [ 'col2' => 'value3' ], // changes
    [ 'col1' => 'value' ] // where clause
);

$context->insertOrUpdate('table', // update triggered when primary key duplicate is detected
    [ 'col1' => 'value', 'col2' => 'value2' ], // fields when insert
    [ 'col2' => 'value3' ] // fields when update
);

$context->setRegistryItem('foo', 'bar');
$context->getRegistryItem('foo'); // bar
```

## File Upload handler

This single function does many logic checks to handle a file upload safely.

```php
$result = \PerrysFramework\FileUploadUtils::receiveUploadedFile(
    fileItem: $_FILE['myfile'], 
    target: __DIR__.'/uploads/file.png',
    maxFileSize: 10 * 1024 * 1024,
    mimeTypePrefix: 'image/'
);

var_dump($result);
```

## HTTP Client

Simple HTTP client based on libcurl with some safety checks to handle any HTTP request.

```php
<?php

$client = \PerrysFramework\HttpClient();
$result = $client->request('https://ip.anysrc.net/plain');

var_dump($result);
var_dump($client->lastHttpReponseCode);
var_dump($client->lastCurlInfo);
```

Also posted on [news.indieweb.org](https://news.indieweb.org/en){:.u-syndication}.
