---
author: christian
title: PHP Sessions verwalten
language: german
tags: ['php', 'software development']
---

PHP Sessions haben besonders auf einem shared Hosting ein Problem:
Möchte man ein eigenes Ablaufdatum definieren wird es kompliziert.

Selbst wenn man die Berechtigung hat die php.ini Einstellungen `session.gc_maxlifetime`,
und `session.cookie_lifetime` zu ändern, gibt es meistens einen vom Provider eingerichteten
Cronjob, welcher einfach die entsprechenden Session Dateien löscht ohne die vom Entwickler
eingestellten Session Timeouts zu respektieren.

Das einzige was dann bleibt, ist den `session_save_path` zu verschieben. Dann muss man sich
allerdings selbst um die ordentliche Löschung der Session Dateien kümmern.

## Ein Beispiel

Das folgende Beispiel konfiguriert den Session Manager von PHP so, dass die Session Dateien
in einem eigenen Ordner abgelegt werden und das gewünschte Session Timeout benutzt wird.

Damit man die Session Dateien mit einem PHP Script auslesen kann, wird das Format in dem die
Sessions gespeichert werden auf `php_serialize` umgestellt.

Die Session ID wird alle 12 Stunden neu generiert und das Cookie im Browser damit ausgetauscht.

Eine Abfrage um der europäischen Datenschutz&shy;grundverordnung nachzukommen, ist ebenfalls
eingebaut. Bevor diese nicht bestätigt wurde, werden keine Cookies im Browser angelegt.

```php
<?php

// the desired timeout
$sessionTimeout = 60 * 60 * 24 * 14; // 14d
$sessionRegenerateTimeout = 60 * 60 * 12; // 12h
$cookieTimeout = 60 * 60 * 24 * 365; // 1y

// default cookie params
$cookie_params = array(
    "path" => '/',
    "domain" => $_SERVER['SERVER_NAME'],
    "secure" => true,
    "httponly" => true,
    "samesite" => 'Lax',
);

// change session directory
session_save_path("/my/temp/outside/of/documentroot/sessions");

// change session timeout
ini_set("session.gc_maxlifetime", $sessionTimeout);
ini_set("session.cookie_lifetime", $sessionTimeout);

// change format handler for session files
ini_set("session.serialize_handler", "php_serialize");

// set cookie settings
session_set_cookie_params(array_merge($cookie_params, array(
    "lifetime" => $sessionTimeout,
)));

// start session if cookie consent exists
$sessionInit = false;
if (isset($_COOKIE['cookie_consent']) && $_COOKIE['cookie_consent']==1)
{
    // Init Session
    session_start();

    // Regenerate session id
    if (!isset($_SESSION['timeout']))
    {
        $_SESSION['timeout'] = time();
    }
    if ($_SESSION['timeout'] + $sessionRegenerateTimeout < time())
    {
        // mark current session for deletion
        $_SESSION['expired'] = true;

        // create a new session
        session_regenerate_id();

        // remove the expired flag from the current session
        unset($_SESSION['expired']);
        $_SESSION['timeout'] = time();
    }

    $sessionInit = true;
}

// delete all cookies if not
else if (is_array($_COOKIE) && count($_COOKIE) > 0)
{
    // no cookie consent, so remove the cookies
    foreach($_COOKIE as $key => $value)
    {
        setcookie($key, "", array_merge($cookie_params, array(
            "expires" => 0,
        )));
    }
}

// set cookie consent if "I accept" button was clicked
if ($_SERVER['REQUEST_METHOD'] === "POST" && isset($_POST['cookieconfirm']))
{
    setcookie("cookie_consent", 1, array_merge($cookie_params, array(
        'expires' => time() + $cookieTimeout,
    )));
}

// now use $sessionInit to decide if the app can so things
// or show a "accept cookies please" dialog
```

## Sessions aufräumen

Ein `cron.php` Script dient dann zum periodischen löschen von abgelaufenen bzw nicht mehr
verwendeten Session Dateien. Das Script sollte zum Beispiel ein Mal pro Stunde aufgerufen
werden.

Alle Session Dateien welche mit `expired=true` markiert sind, werden ohne Rücksicht auf
das Session Timeout gelöscht. Alle anderen Dateien werden anhand des Zeitpunktes der letzten
Dateiänderung gelöscht.

```php
<?php

$sessionPath = "/my/temp/outside/of/documentroot/sessions";
$sessionTimeout = 60 * 60 * 24 * 14; // 14d
$sessionCleanupTimeout = $sessionTimeout + (60 * 60); // session timeout + 1h

$sessionFiles = glob($sessionPath."/sess_*", GLOB_NOSORT);

if (is_array($sessionFiles) && count($sessionFiles) > 0)
{
    foreach($sessionFiles as $sessionFile)
    {
        if (is_file($sessionFile))
        {
            // delete by modification time
            if (filemtime($sessionFile) < time() - $sessionCleanupTimeout)
            {
                if (unlink($sessionFile) !== true)
                {
                    echo "Failed to delete session file '".$sessionFile."'\n";
                }
            }
            // delete by expired flag
            else
            {
                $sessionData = unserialize(file_get_contents($sessionFile));

                if ($sessionData === false)
                {
                    echo "Failed to deserialize session file '".$sessionFile."'\n";
                }
                else if (isset($sessionData['expired']) && $sessionData['expired'] === true)
                {
                    if (unlink($sessionFile) !== true)
                    {
                        echo "Failed to delete session file '".$sessionFile."'\n";
                    }
                }
            }

        }
    }
}
```

Eine Demo dieser Mechanik gibt es hier:

[https://yaynay.dingetun.net/changeme](https://yaynay.dingetun.net/changeme)
