# LemonLDAP::NG dockers

Some docker for a scalable [Lemonldap::NG](https://lemonldap-ng.org)
installation, ready to use with a Redis server to share sessions and a
PostgreSQL server to share configuration. See docker-compose example.

List:
 - [yadd/lemonldap-ng-portal](./portal): the portal
 - [yadd/lemonldap-ng-manager](./manager): the manager
 - [yadd/lemonldap-ng-full](./full): the portal and the manager in the same image
 - [yadd/lemonldap-ng-ssoaas-fastcgi-server](./ssoaas-fastcgi-server): a FastCGI
   server to enable [SSOaaS](https://lemonldap-ng.org/documentation/latest/ssoaas.html)
 - [yadd/lemonldap-ng-pg-database](./pg): a ready to use PostgreSQL database
 - [yadd/lemonldap-ng-cron](./cron): a simple LLNG maintenance tasks runner,
   to be used if tasks are disabled on portals. See examples.

The [yadd/lemonldap-ng-base](./base) isn't directly usable, just a base
to build Lemonldap::NG components.

Image uses [S6 overlay](https://github.com/just-containers/s6-overlay) except
PostgreSQL database, based on [postgres:bullseye](https://hub.docker.com/_/postgres).

[LemonLDAP::NG](https://lemonldap-ng.org) is installed using
[Debian backports packages](https://backports.debian.org/), so using the
last published version.

You can also use [dev](./dev) to build an image using the upstream repository.
Set `BRANCH` to choose the upstream branch to clone.

## Docker-compose examples:

### 1. Simple standalone LemonLDAP::NG

```yaml
version: "3.4"

services:
  llng:
    image: yadd/lemonldap-ng-full
    environment:
      - LOGGER=stderr
      - USERLOGGER=stderr
    port: 80:80
```

### 2. Separate portal and manager, configuration shared by filesystem

In this example, manager is available on port 81, portal on port 80.

```yaml
version: "3.4"

services:
  auth:
    image: yadd/lemonldap-ng-portal
    environment:
      - LOGGER=stderr
      - USERLOGGER=stderr
    volumes:
      - ./llng-var:/var/lib/lemonldap-ng
    port: 80:80

  auth:
    image: yadd/lemonldap-ng-manager
    environment:
      - LOGGER=stderr
      - USERLOGGER=stderr
    volumes:
      - ./llng-var:/var/lib/lemonldap-ng
    port: 81:80
```

### 3. Separate portal and manager using real databases

In this example, manager is available on port 81, portal on port 80.
Configuration is stored in a PostgerSQL database, sessions in a Redis server.

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

  auth:
    image: yadd/lemonldap-ng-portal
    environment:
      - PG_SERVER=db
      - REDIS_SERVER=redis:6379
      - LOGGER=stderr
      - USERLOGGER=stderr
    port: 80:80

  auth:
    image: yadd/lemonldap-ng-manager
    environment:
      - PG_SERVER=db
      - REDIS_SERVER=redis:6379
      - LOGGER=stderr
      - USERLOGGER=stderr
    port: 81:80
```

### 4. Scalability

Here a [haproxy](https://www.haproxy.org/) server balance requests between
5 portals. It handles also he manager.
To avoid multiplicating maintenance tasks, a [yadd/lemonldap-ng-cron](./cron)
service handle them and portals are configured with `PORTAL_CRON=no`

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

  portal:
    image: yadd/lemonldap-ng-portal
    environment:
      - LOGGER=stderr
      - USERLOGGER=stderr
      - PG_SERVER=db
      - REDIS_SERVER=redis:6379
      - PORTAL_CRON=no
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    scale: 5

  cron:
    image: yadd/lemonldap-ng-cron
    environment:
      - LOGGER=stderr
      - USERLOGGER=stderr
      - PG_SERVER=db
      - REDIS_SERVER=redis:6379
      - PORTAL_CRON=no
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started

  manager:
    image: yadd/lemonldap-ng-manager
    environment:
      - LOGGER=stderr
      - USERLOGGER=stderr
      - PG_SERVER=db
      - REDIS_SERVER=redis:6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started

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

## Copyright and license

Copyright: Xavier Guimard <yadd@debian.org>.

License: [GNU General Public License v2.0](./LICENSE)
