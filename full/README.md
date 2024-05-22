# yadd/lemonldap-ng-full

Lemonldap::NG portal and manager based on [yadd/lemonldap-ng-base](https://github.com/guimard/llng-docker/blob/master/base/README.md#readme)

Note that you should share sessions and configuration to use. See
docker-compose example to see how to do this using redis and
[PostgreSQL](https://github.com/guimard/llng-docker/blob/master/pg/README.md#readme).

## Tags

* `stable`: latest lemonldap-ng\* packages from Debian backports
* `stable-no-s6`: the same without [S6-overlay](https://github.com/just-containers/s6-overlay)
* `2.x.x`: versioned lemonldap-ng\* packages from Debian backports
* `2.x.x-no-s6`: the same without [S6-overlay](https://github.com/just-containers/s6-overlay)

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

* Other:
  * `DEFAULT_WEBSITE` = `no`, if set to `yes` the default Nginx website is
    deleted
  * `PROTECTION` = `manager`, set it to `none` if you don't want to protect
    the manager by LemonLDAP-NG itself

## Docker-compose example

Example with Crowdsec enabled, Postgres database and Redis to share sessions.

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
      - LOGGER=stderr
      - USERLOGGER=stderr
      - CROWDSEC_SERVER=http://crowdsec:8080
      - CROWDSEC_KEY=myrandomstring
      - CROWDSEC_ACTION=reject
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
  crowdsec:
    image: crowdsecurity/crowdsec
    environment:
      - BOUNCER_KEY_llng=myrandomstring
```

## Repository and bug reports

* Repository: [github.com/guimard/llng-docker](https://github.com/guimard/llng-docker/tree/master/full)
* [Dockerfile](https://github.com/guimard/llng-docker/blob/master/full/Dockerfile)
* [Issues database](https://github.com/guimard/llng-docker/issues)

## Copyright and license

Copyright:
 * 2018-2024, Xavier Guimard <yadd@debian.org>
 * 2023-2024, LINAGORA <https://linagora.com>

License: [GNU General Public License v2.0](https://github.com/guimard/llng-docker/blob/master/LICENSE)
