# yadd/lemonldap-ng-base

Base image for `yadd/lemonldap-ng-*` dockers. Does nothing except configuring
LemonLDAP::NG.

## Tags

* `stable`: latest lemonldap-ng\* packages from Debian backports
* `stable-no-s6`: the same without [S6-overlay](https://github.com/just-containers/s6-overlay)
* `2.x.x`: versioned lemonldap-ng\* packages from Debian backports
* `2.x.x-no-s6`: the same without [S6-overlay](https://github.com/just-containers/s6-overlay)

## Features

* Always use "Overlay" configuration backend.
  See [Override configuration parameters](#override-configuration-parameters)
* Update current configuration using given variables :
  * set domain (`SSODOMAIN`)
  * set portal (`PORTAL`)
  * set log level (`LOGLEVEL`)
  * if `REDIS_SERVER` is set, change `globalStorage` to `Apache::Session::Browseable::Redis`
    and configure it _(indexes given by `REDIS_INDEXES`, default: "uid mail")_
* Upload local configuration into PostgreSQL database if:
  * `PG_SERVER` is given AND
  * PostgreSQL table is empty
* Initialize LLNG configuration key to a random value if not already initialized or if
  `FORCE_KEY_REGENERATION` is set to `yes`

> It is generaly a good idea to set this value to `yes`

## Variables and default values

* `SSODOMAIN` = `example.com`
* `CROWDSEC_SERVER` = _(full base url, example: http://myserver:8080)_
* `CROWDSEC_POLICY` = `reject` _(possible values: warn, reject)_
* `CROWDSEC_KEY` = _(required, given by `cscli bouncers add mylemon`)_
* `PORTAL` = `http://auth.example.com/` _(full URL needed here)_
* `LOGLEVEL` = `info` _(possible values: debug, info, notice, warn, error)_
* `LOGGER` = `syslog` _(possible values: stderr, syslog)_
* `USERLOGGER` = `syslog` _(possible values: stderr, syslog)_
* `FORCE_KEY_REGENERATION` = `no`
* Configuration and persistent session storage
  * `PG_SERVER` =
  * `PG_DATABASE` = `lemonldapng`
  * `PG_USER` = `lemonldap`
  * `PG_PASSWORD` = `lemonldap`
  * `PG_TABLE` = `lmConfig`
  * `PG_OPTIONS` =
  * Advanced _(see DBI(3pm) for more)_
    * `DBI_CHAIN` = **if** `$PG_SERVER` **then** `DBI:Pg:database=$PG_DATABASE;host=$PG_SERVER;$PG_OPTIONS` **else** `""`
    * `DBI_USER` = `$PG_USER`
    * `DBI_PASSWORD` = `$PG_PASSWORD`
* Session storage:
  * `REDIS_SERVER` =
  * `REDIS_INDEXES` = `_whatToTrace _session_kind _utime ipAddr _httpSessionType _user` _(see Apache::Session::Browseable::Redis)_
  * Used only if `REDIS_SERVER` is empty and configuration database is empty:
    * `PG_PERSISTENT_SESSIONS_TABLE` = `psessions`
    * `PG_SESSIONS_TABLE` = `sessions`
    * `PG_SAML_TABLE` = `samlsessions`
    * `PG_OIDC_TABLE` = `oidcsessions`
    * `PG_CAS_TABLE` = `cassessions`
* Session purge tasks:
  * `HANDLER_CRON` = `yes`
  * `PORTAL_CRON` = `yes`

**LemonLDAP::NG logs**: when using default values _(syslog)_, logs are stored in `/var/log/`

### Advanced PostgreSQL configuration

Use `PG_OPTIONS` to set additional parameters. Examples:

 * Change default port: `PG_OPTIONS=port=23456`
 * Change SSL mode: `PG_OPTIONS=sslmode=require`
 * Both: `PG_OPTIONS=port=23456;PG_OPTIONS=sslmode=require`

Or use `DBI_CHAIN` directly _(and then `DBI_USER` and `DBI_PASSWORD`)_:

```
DBI_CHAIN=dbi:Pg:dbname=lemonldapng;host=postgresql.host.tld;port=23456;sslmode=require
DBI_USER=pguser
DBI_PASSWORD=pgpassword
```

### Override configuration parameters

You can easily override any Lemonldap::NG configuration parameter using the
overlay system _(starting from 2.19.0-1 tag)_. Simply push files into `/over`
directory:
  * filename is the configuration parameter name
  * content is the raw content or a JSON content

You can easily override any Lemonldap::NG configuration parameter using a
environment variable set to `OVERRIDE_<parameter name>`. For example, to set
`checkXSS`to 0 and `exportedVars` to `{"Name":"cn"}` in a docker-compose.yml
file, use:

```yaml
  environment:
    - OVERRIDE_checkXSS=0
    - OVERRIDE_exportedVars={"Name":"cn"}
```

Note that JSON notation is supported only for objects and arrays.

To modify subkeys, use "\_" separator. For example to set the subkey "uid" of
key "ldapExportedVars" to "cn", use:
```yaml
  environment:
    - OVERRIDE_ldapExportedVars_uid=cn
```

Note that the container key _(here ldapExportedVars)_ must exist.

## Docker-compose example

Example with yadd/lemonldap-ng-portal and crowdesc enabled

```yaml
version: "3.4"

services:
  pgdb:
    image: yadd/lemonldap-ng-pg-database
    environment:
      - POSTGRES_PASSWORD=zz
    healthcheck:
      test: "exit 0"
  redis:
    image: redis
  base:
    image: yadd/lemonldap-ng-portal
    environment:
      - PG_SERVER=pgdb
      - REDIS_SERVER=redis:6379
      - LOGGER=stderr
      - USERLOGGER=stderr
      - OVERRIDE_exportedVars={"cn":"cn","mail":"mail","uid":"uid"}
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

* Repository: [github.com/guimard/llng-docker](https://github.com/guimard/llng-docker/tree/master/base)
* [Dockerfile](https://github.com/guimard/llng-docker/blob/master/base/Dockerfile)
* [Issues database](https://github.com/guimard/llng-docker/issues)

## Copyright and license

Copyright:
 * 2018-2023, Xavier Guimard <yadd@debian.org>
 * 2023, LINAGORA <https://linagora.com>

License: [GNU General Public License v2.0](https://github.com/guimard/llng-docker/blob/master/LICENSE)
