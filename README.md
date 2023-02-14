# LemonLDAP::NG dockers

Some docker for a scalable [Lemonldap::NG](https://lemonldap-ng.org)
installation, ready to use with a Redis server to share sessions and a
PostgreSQL server to share configuration. See docker-compose example.

List:
 - [yadd/lemonldap-ng-portal](./portal): the portal
 - [yadd/lemonldap-ng-manager](./manager): the manager
 - [yadd/lemonldap-ng-pg-database](./pg): a ready to use PostgreSQL database

The [yadd/lemonldap-ng-base](./base) isn't directly usable, just a base
to build Lemonldap::NG components.

Image uses [S6 overlay](https://github.com/just-containers/s6-overlay) except
PostgreSQL database, based on [postgres:bullseye](https://hub.docker.com/_/postgres).

[LemonLDAP::NG](https://lemonldap-ng.org) is installed using
[Debian backports packages](https://backports.debian.org/), so using the
last published version.

## Docker-compose example:

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
      - PG_SERVER=db
      - REDIS_SERVER=redis:6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
  manager:
    image: yadd/lemonldap-ng-manager
    environment:
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
