# yadd/lemonldap-ng-portal

Lemonldap::NG portal based on [yadd/lemonldap-ng-base](https://github.com/guimard/llng-docker/blob/master/base/README.md#readme)

This image is then scalable _(see docker-compose example)_:
* use a configured PostgreSQL database _(you can use [yadd/lemonldap-ng-pg-database](https://github.com/guimard/llng-docker/blob/master/pg/README.md#readme))_
* share your sessions with a Redis server

## Tags

* `stable`: latest lemonldap-ng\* packages from Debian backports
* `stable-no-s6`: the same without [S6-overlay](https://github.com/just-containers/s6-overlay)
* `2.x.x`: versioned lemonldap-ng\* packages from Debian backports
* `2.x.x-no-s6`: the same without [S6-overlay](https://github.com/just-containers/s6-overlay)

You can also use the same tags with suffix "-hiperf" to use the portal with
a better _(but more resource intensive)_ engine.

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

> When running multiple portals using the same database, you should keep portal
cron tasks only on one portal: Set environment variable `PORTAL_CRON` to `no`
in all portal containers except one _(or use one of yadd/lemonldap-ng-cron or
yadd/lemonldap-ng-cron-task)_.

* `NPROC`: the minimal number of FastCGI server to start _(default: 7)_
* `ENGINE`: the FastCGI server engine. _(default: [FCGI](https://metacpan.org/pod/FCGI))_.
  You can try [FCGI::Engine::ProcManager](https://metacpan.org/pod/FCGI::Engine::ProcManager).
  See also [High performance portal](../uwsgi-portal/README.md).
* `RELAY`: list of reverse-proxies to set. syntax: `<servername>=https://<proxy-dest>/;<servername>=https://<proxy-dest>/...`

See also [yadd/lemonldap-ng-base](https://github.com/guimard/llng-docker/blob/master/base/README.md#readme)

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
      test: ["CMD-SHELL", "pg_isready"]
      interval: 10s
      timeout: 5s
      retries: 5
  redis:
    image: redis
  portal:
    image: yadd/lemonldap-ng-portal
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
        condition: service_started
  manager:
    image: yadd/lemonldap-ng-manager
    environment:
      - PG_SERVER=db
      - REDIS_SERVER=redis:6379
      - LOGGER=stderr
      - USERLOGGER=stderr
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
      portal:
        condition: service_started

  crowdsec:
    image: crowdsecurity/crowdsec
    environment:
      - BOUNCER_KEY_llng=myrandomstring

  haproxy:
    image: haproxy:2.6-bullseye
    ports:
      - 80:80
    volumes:
      - ./haproxy:/usr/local/etc/haproxy:ro
    sysctls:
      - net.ipv4.ip_unprivileged_port_start=0
    depends_on:
      - portal
      - manager
```

## Repository and bug reports

* Repository: [github.com/guimard/llng-docker](https://github.com/guimard/llng-docker/tree/master/portal)
* [Dockerfile](https://github.com/guimard/llng-docker/blob/master/portal/Dockerfile)
* [Issues database](https://github.com/guimard/llng-docker/issues)

## Copyright and license

Copyright:
 * 2018-2024, Xavier Guimard <yadd@debian.org>
 * 2023-2024, LINAGORA <https://linagora.com>

License: [GNU General Public License v2.0](https://github.com/guimard/llng-docker/blob/master/LICENSE)
