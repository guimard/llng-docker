# yadd/lemonldap-ng-full

Lemonldap::NG portal and manager based on [yadd/lemonldap-ng-base](https://github.com/guimard/llng-docker/blob/master/base/README.md#readme)

Note that you should share sessions and configuration to use. See
docker-compose example to see how to do this using redis and
[PostgreSQL](https://github.com/guimard/llng-docker/blob/master/pg/README.md#readme).

## Tags

* `stable`: latest lemonldap-ng\* packages from Debian backports
* `2.x.x`: versioned lemonldap-ng\* packages from Debian backports

## Features _(inherited from [yadd/lemonldap-ng-base](https://github.com/guimard/llng-docker/blob/master/base/README.md#readme))_

* Update current configuration using given variables :
  * set domain (`SSODOMAIN`)
  * set portal (`PORTAL`)
  * set log level (`LOGLEVEL`)
  * if `REDIS_SERVER` is set, change `globalStorage` to `Apache::Session::Browseable::Redis` and configure it _(indexes given by `REDIS_INDEXES`, default: "uid mail")_
* Upload local configuration into PostgreSQL database if:
  * `PG_SERVER` is given AND
  * PostgreSQL table is empty

## Variables and default values

See [yadd/lemonldap-ng-base](https://github.com/guimard/llng-docker/blob/master/base/README.md#readme)

## Docker-compose example

```yaml
version: "3.4"

services:
  db:
    image: yadd/lemonldap-ng-pg-database
    environment:
      - POSTGRES_PASSWORD=zz
    healthcheck:
      test: "exit 0"
  redis:
    image: redis
  llng:
    image: yadd/lemonldap-ng-full
    ports:
      - 80:80
    environment:
      - PG_SERVER=db
      - REDIS_SERVER=redis:6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
```

## Repository and bug reports

* Repository: [github.com/guimard/llng-docker](https://github.com/guimard/llng-docker/tree/master/full)
* [Dockerfile](https://github.com/guimard/llng-docker/blob/master/full/Dockerfile)
* [Issues database](https://github.com/guimard/llng-docker/issues)

## Copyright and license

Copyright: Xavier Guimard <yadd@debian.org>.

License: [GNU General Public License v2.0](../LICENSE)
