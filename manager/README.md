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
  - `MANAGER_API_OAUTH2_CLIENTS` = _(space or comma separated list of OIDC
    client IDs allowed to use the API with an access token obtained by client
    credentials grant)_
  - `MANAGER_API_OAUTH2_SCOPE` = `manager-api`, scope required in these access
    tokens _(empty value: no scope check)_
  - `MANAGER_API_ALLOW` = _(space or comma separated list of IP addresses or
    networks allowed to access the API, all others are rejected)_
  - `MANAGER_API_AUTHBASIC` = _(`<login>:<password>` to add an Nginx basic
    authentication on the API)_
  - `MANAGER_API_READONLY` = `no`, set it to `yes` to allow only `GET` and
    `HEAD` requests
  - `MANAGER_API_PORT` = _(serve the API on this dedicated port, whatever the
    `Host` header, instead of the `manager-api.$SSODOMAIN` virtual host)_

## Manager API

The Manager API allows to modify LemonLDAP::NG configuration _(OIDC RPs,
SAML SPs, CAS applications, menu)_ and users second factors. **It performs no
authentication by itself**, so it's disabled by default. When enabled with
`MANAGER_API=yes`, it's served on `manager-api.$SSODOMAIN` and at least one of
`MANAGER_API_OAUTH2_CLIENTS`, `MANAGER_API_ALLOW` or `MANAGER_API_AUTHBASIC`
is required. If the given variables would leave the API unprotected _(or are
invalid)_, an error is logged and the API stays disabled.

Available protections _(they can be combined, except OAuth2 and basic
authentication which both use the `Authorization` header)_:

- **OAuth2 client credentials** _(recommended)_: API clients are
  applications, not users. Declare each of them as an OIDC Relying Party
  allowed to use the _client credentials_ grant, then list their client IDs
  in `MANAGER_API_OAUTH2_CLIENTS`. The API then requires an access token
  _(`Authorization: Bearer ...`)_ that:
  - was issued by the client credentials grant _(tokens tied to a user
    session are rejected)_
  - was issued to one of the listed clients _(any other client is rejected)_
  - contains the `MANAGER_API_OAUTH2_SCOPE` scope _(default: `manager-api`)_

  Tokens are short-lived, each client has its own secret and the client ID
  appears in LemonLDAP::NG logs. Example:
  ```shell
  TOKEN=$(curl -s -u myclient:mysecret -d grant_type=client_credentials \
    -d scope=manager-api https://auth.example.com/oauth2/token | jq -r .access_token)
  curl -H "Authorization: Bearer $TOKEN" https://manager-api.example.com/api/v1/status
  ```
- **IP filtering**: `MANAGER_API_ALLOW="10.1.2.0/24 192.168.0.12"`. Don't
  forget `FORWARDED_BY` if you're behind a reverse proxy, else the proxy
  address is checked. But `FORWARDED_BY` must contain only your proxy
  addresses: if it trusts any client _(`0.0.0.0/0` or `::/0`)_, the client
  address can be spoofed, so the allow list is refused if no other protection
  is set. `0.0.0.0/0` and `::/0` are also refused in `MANAGER_API_ALLOW` if
  no other protection is set
- **Nginx basic authentication**: `MANAGER_API_AUTHBASIC=<login>:<password>`
- **Read-only mode**: `MANAGER_API_READONLY=yes` rejects all modification
  requests _(useful for monitoring or inventory)_. Note that read requests
  return secrets _(OIDC client secrets for example)_, so this doesn't replace
  a strong protection

By default, the API is a virtual host on the main port. With
`MANAGER_API_PORT=8081` for example, it's served instead on port 8081 whatever
the `Host` header, so a reverse proxy can route `/api/` of the manager site to
this port _(`https://manager.example.com/api/v1/...`)_ or it can be kept
unexposed outside of your internal network. With `TLS_CERT_FILE`, this port
uses TLS too.

Example: API usable only from the internal network by the `ci-deploy` OIDC
client:

```yaml
  manager:
    image: yadd/lemonldap-ng-manager
    environment:
      - MANAGER_API=yes
      - MANAGER_API_OAUTH2_CLIENTS=ci-deploy
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
