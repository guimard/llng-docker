# yadd/lemonldap-ng-cron

Just a cron service that maintain LLNG session databases. When using many
portal instances, disable cron in it and use a dedicated yadd/lemonldap-ng-cron
to run sessions databases maintenance.

## Docker example

```yaml
services:

  llng-db:
    image: yadd/lemonldap-ng-pg-database
    environment:
      - POSTGRES_PASSWORD=pwd
    healthcheck:
      test: "exit 0"

  redis:
    image: redis

  auth:
    image: yadd/lemonldap-ng-portal
    hostname: auth.example.com
    environment:
      - SSODOMAIN=example.com
      - PORTAL=https://auth.example.com
      - LOGLEVEL=notice
      - LOGGER=stderr
      - USERLOGGER=stderr
      - PG_SERVER=llng-db
      - REDIS_SERVER=redis:6379
      - PORTAL_CRON=no
    depends_on: 
      llng-db:
        condition: service_healthy
    scale: 3
    networks:
      - db
      - frontend
      - sso

  cron:
    image: yadd/lemonldap-ng-cron
    environment:
      - SSODOMAIN=example.com
      - PORTAL=https://auth.example.com
      - LOGLEVEL=notice
      - LOGGER=stderr
      - USERLOGGER=stderr
      - PG_SERVER=llng-db
      - REDIS_SERVER=redis:6379
    depends_on: 
      llng-db:
        condition: service_healthy

  manager:
    image: yadd/lemonldap-ng-manager
    environment:
      - SSODOMAIN=example.com
      - PORTAL=https://auth.example.com
      - PG_SERVER=llng-db
      - REDIS_SERVER=redis:6379
      - LOGLEVEL=notice
      - LOGGER=stderr
      - USERLOGGER=stderr
    depends_on:
      llng-db:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - db
      - frontend
      - sso

  haproxy:
    image: haproxy:2.6-bullseye
    ports:
      - 443:443
    volumes:
      - ./haproxy:/usr/local/etc/haproxy:ro
      - ./ssl/both.pem:/etc/ssl/certs/both.pem
    sysctls:
      - net.ipv4.ip_unprivileged_port_start=0
    depends_on:
      - auth
      - manager
```
