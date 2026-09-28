# yadd/lemonldap-ng-portal

Lemonldap::NG portal based on [yadd/lemonldap-ng-base](https://github.com/guimard/llng-docker/blob/master/base/README.md#readme)

Note that you should share sessions and configuration to use. See
docker-compose example to see how to do this using redis and
[PostgreSQL](https://github.com/guimard/llng-docker/blob/master/pg/README.md#readme).

## Tags

- `stable`: alias of `lts-2.21`, the current LTS release
- `stable-no-s6`: the same without [S6-overlay](https://github.com/just-containers/s6-overlay)
- `2.x.x`: versioned lemonldap-ng\* packages from Debian backports
- `2.x.x-no-s6`: the same without [S6-overlay](https://github.com/just-containers/s6-overlay)

## Features _(inherited from [yadd/lemonldap-ng-base](https://github.com/guimard/llng-docker/blob/master/base/README.md#readme))_

- Update current configuration using given variables :
  - set domain (`SSODOMAIN`)
  - set portal (`PORTAL`)
  - set log level (`LOGLEVEL`)
  - if `REDIS_SERVER` is set, change `globalStorage` to `Apache::Session::Browseable::Redis` and configure it _(indexes given by `REDIS_INDEXES`, default: "uid mail")_
- Upload local configuration into PostgreSQL database if:
  - `PG_SERVER` is given AND
  - PostgreSQL table is empty

## Variables and default values

See [yadd/lemonldap-ng-base](https://github.com/guimard/llng-docker/blob/master/base/README.md#readme)

- Other:
  - `DEFAULT_WEBSITE` = `no`, if set to `yes` the default Nginx website is
    deleted
  - `PROTECTION` = `manager`, set it to `none` if you don't want to protect
    the manager by LemonLDAP-NG itself
  - `AUTHBASIC`, if you use `PROTECTION=none`, you can add a basic authentication
    using `AUTHBASIC=<login>:<password>`
  - `MANAGER_API` = `no`, set it to `yes` to enable the
    [Manager API](https://lemonldap-ng.org/manager-api/) on
    `manager-api.$SSODOMAIN` _(see [Manager API](#manager-api) below)_
  - `MANAGER_API_PROTECTION` = `manager`, API protection by LemonLDAP::NG:
    `manager` _(rules of `manager-api.$SSODOMAIN` virtual host)_,
    `<rule>`, `authenticate` _(not recommended)_ or `none` _(web server
    protection only)_
  - `MANAGER_API_TYPE` = _(empty: type set in virtual host configuration)_,
    LemonLDAP::NG handler type used to protect the API: `Main`, `OAuth2`,
    `AuthBasic` or `ServiceToken`
  - `MANAGER_API_ALLOW` = _(space or comma separated list of IP addresses or
    networks allowed to access the API, all others are rejected)_
  - `MANAGER_API_AUTHBASIC` = _(`<login>:<password>` to add an Nginx basic
    authentication on the API)_
  - `MANAGER_API_READONLY` = `no`, set it to `yes` to allow only `GET` and
    `HEAD` requests

## Manager API

The Manager API allows to modify LemonLDAP::NG configuration _(OIDC RPs,
SAML SPs, CAS applications, menu)_ and users second factors. **It performs no
authentication by itself**, so it's disabled by default. When enabled with
`MANAGER_API=yes`, it's served on `manager-api.$SSODOMAIN`. If the given
variables would leave the API unprotected _(or are invalid)_, an error is
logged and the API stays disabled.

Available protections _(they can be combined)_:

- **LemonLDAP::NG protection** _(default: `MANAGER_API_PROTECTION=manager`)_:
  requests are checked by the LemonLDAP::NG handler against the rules of the
  `manager-api.$SSODOMAIN` virtual host. This virtual host doesn't exist in
  default configuration, so no access is granted until you declare it.
  For an API, prefer a non-interactive handler type
  _(the default `Main` type redirects to the portal)_:
  - `MANAGER_API_TYPE=OAuth2` _(recommended)_: clients send an OIDC access
    token _(`Authorization: Bearer ...`)_. Create a dedicated OIDC Relying Party
    allowed to use the _client credentials_ grant, then set the virtual host
    rule to something like
    `$_clientId eq "manager-api-client" and $_scope =~ /(?<!\S)manager-api(?!\S)/`
  - `MANAGER_API_TYPE=ServiceToken`: for applications already protected by
    LemonLDAP::NG that call the API using a `token()` header
  - `MANAGER_API_TYPE=AuthBasic`: login/password checked by the portal
    _(requires the portal REST server)_, then use a rule like `$uid eq "admin"`
- **IP filtering**: `MANAGER_API_ALLOW="10.1.2.0/24 192.168.0.12"`. Don't
  forget `FORWARDED_BY` if you're behind a reverse proxy, else the proxy
  address is checked
- **Nginx basic authentication**: `MANAGER_API_AUTHBASIC=<login>:<password>`
  _(can't be combined with `OAuth2` or `AuthBasic` handler types that use
  the same `Authorization` header)_
- **Read-only mode**: `MANAGER_API_READONLY=yes` rejects all modification
  requests _(useful for monitoring or inventory)_. Note that read requests
  return secrets _(OIDC client secrets for example)_, so this doesn't replace
  a strong protection

`MANAGER_API_PROTECTION=none` is accepted only with `MANAGER_API_ALLOW` _(not
`0.0.0.0/0` or `::/0`)_ and/or `MANAGER_API_AUTHBASIC`. LemonLDAP::NG rules
`skip` and `unprotect` are refused.

Example: API usable only from the internal network with an OAuth2 access
token:

```yaml
  manager:
    image: yadd/lemonldap-ng-manager
    environment:
      - MANAGER_API=yes
      - MANAGER_API_TYPE=OAuth2
      - MANAGER_API_ALLOW=10.0.0.0/8
```

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

- Repository: [github.com/guimard/llng-docker](https://github.com/guimard/llng-docker/tree/master/manager)
- [Dockerfile](https://github.com/guimard/llng-docker/blob/master/manager/Dockerfile)
- [Issues database](https://github.com/guimard/llng-docker/issues)

## Copyright and license

Copyright:

- 2018-2024, Xavier Guimard <yadd@debian.org>
- 2023-2024, LINAGORA <https://linagora.com>

License: [GNU General Public License v2.0](https://github.com/guimard/llng-docker/blob/master/LICENSE)
