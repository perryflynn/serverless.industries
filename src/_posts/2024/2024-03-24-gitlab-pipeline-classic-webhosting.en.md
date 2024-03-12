---
author: christian
title: Deploy to a classic Webhosting with GitLab CI
locale: en
tags: [ gitlab, continuous integration, webspace ]
---

Some time ago I helped with making and deploying a small Website. The Website was made in
Symfony 6.x and is deployed to a Webspace without any SSH access. Just FTP.

For quality resons I still wanted to have separate staging and production deployments
via GitLab CI. This would allow users easily make changes on the Website via Merge
Requests.

## Migration File

Since the Webhosting does not provide any SSH access, we have to run Database Migrations with
a small helper PHP script. The Pipeline will replace `__ACCESS-TOKEN__` with a random password
and `__PHP_BINARY__` with the full path to the PHP CLI.

Then the Pipeline will execute the migration script with `curl`.

```php
<?php

if (!( isset($_POST['access_token']) && $_POST['access_token']==="__ACCESS_TOKEN__" &&
    $_POST['access_token']!==str_replace("-", "_", "__ACCESS-TOKEN__") ))
{
    header("HTTP/1.1 403 Forbidden");
    exit();
}

error_reporting(-1);
ini_set('display_errors', 'on');

echo "\n\nStart Migration Script\n\n";

chdir(__DIR__."/../");
echo "Current working directory: ".getcwd()."\n";

function symfony($scmd)
{
    $php = "__PHP_BINARY__";
    $cmd = '/bin/bash -c "'.$php.' bin/console '.$scmd.' 2>&1"';
    echo "Command: ".$cmd."\n";
    var_dump(system($cmd));
    echo "\n";
}

// run symfony commands
echo "Clear cache for prod:\n";
symfony('cache:clear --env=prod');

echo "Warm up cache for prod:\n";
symfony('cache:warmup --env=prod');

echo "Start database migrations:\n";
symfony('doctrine:migrations:migrate --allow-no-migration --no-interaction');

// delete itself
unlink(__FILE__);
echo "Done\n";
```

## Pipeline File

The Pipeline is using a Debian Bookworm image. It installs all required tools like `curl`, `pwgen`,
`lftp` and the PHP CLI. Then the required PHP Packages will be installed by composer.

For uploading the PHP files to the Webspace, `lftp` is used.

```yml
stages:
  - deploy

#
# -> Templates
#

.tpl:docker:
  image: debian:bookworm-slim
  before_script:
    # install php and other tools
    - |
      export DEBIAN_FRONTEND=noninteractive
      APTOPTS="--yes --no-install-recommends -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"

      apt-get update
      apt-get $APTOPTS upgrade
      apt-get $APTOPTS dist-upgrade
      apt-get $APTOPTS install unzip curl wget ca-certificates gnupg2 lftp jq pwgen \
          php8.2-cli php8.2-bcmath php8.2-curl php8.2-gd php8.2-gmp php8.2-imap \
          php8.2-intl php8.2-mbstring php8.2-mysql php8.2-odbc \
          php8.2-opcache php8.2-sqlite3 php8.2-xml php8.2-zip

    # install composer
    # https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
    - |
      EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
      php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
      ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

      if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
      then
          >&2 echo 'ERROR: Invalid installer checksum'
          rm composer-setup.php
          exit 1
      fi

      php composer-setup.php --quiet
      RESULT=$?
      rm composer-setup.php

      mv composer.phar /usr/bin
      ln -s /usr/bin/composer.phar /usr/bin/composer

    # install application dependencies
    - |
      export APP_ENV=prod
      export APP_DEBUG=0
      composer install --no-dev --optimize-autoloader
      php bin/console cache:clear
  tags:
    - docker

.tpl:deploy:
  extends: .tpl:docker
  stage: deploy
  script:
    # app settings
    - 'echo "DATABASE_URL=''$var_databaseurl''" > .env.local'
    - 'echo "MANAGER_PASSWORD=''$MANAGER_PASSWORD''" >> .env.local'
    - cat .env.local
    - composer dump-env prod

    - 'export MIGRATION_TOKEN=$(pwgen -1 32 1)'
    - sed -i "s|__ACCESS_TOKEN__|$MIGRATION_TOKEN|g" public/migrate.php
    - sed -i "s|__PHP_BINARY__|/usr/local/pd-admin2/php-8.2.15/bin/php-cli|g" public/migrate.php

    # upload
    - 'lftp -e "mirror --reverse --delete --only-newer --no-symlinks --parallel=5 --exclude=.git . $var_ftpfolder/" -u "$var_ftpuser,$var_ftppassword" ftp.example.com'

    # run database migrations
    - 'echo "Migration Token: $MIGRATION_TOKEN"'
    - 'echo "Start migration"'
    - 'curl -X POST -F access_token=$MIGRATION_TOKEN ${var_url}/migrate.php'

    # cleanup
    - rm -f .env.local*

#
# -> Jobs
#

deploy:app:demo:
  extends: .tpl:deploy
  only:
    - demo
  variables:
    var_env: dev
    var_databaseurl: "$DEMO_DATABASE_URL"
    var_ftpuser: ftpusername
    var_ftppassword: "$DEMO_FTP_PASSWD"
    var_ftpfolder: /website-demo
    var_domainname: demo.example.com
    var_url: http://demo.example.com

deploy:app:live:
  extends: .tpl:deploy
  only:
    - live
  variables:
    var_env: prod
    var_databaseurl: "$PROD_DATABASE_URL"
    var_ftpuser: ftpusername
    var_ftppassword: "$PROD_FTP_PASSWD"
    var_ftpfolder: /website-prod
    var_domainname: example.com
    var_url: https://example.com
```

The following Pipeline Variables have to be defined:

- `MANAGER_PASSWORD`: Hashed password for the management backend
- `DEMO_DATABASE_URL`: Database URI for staging
- `DEMO_FTP_PASSWD`: FTP password for staging
- `PROD_DATABASE_URL`: Database URI for production
- `PROD_FTP_PASSWD`: FTP password for production

The code is deployed to production if something was pushed to the `live` branch. If code was 
pushed to the `demo` branch, the staging environment is getting updated.

Now back from 2006 to the present. 🙂

Seriously, why are there still providers which only offering FTP?
