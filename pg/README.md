# yadd/lemonldap-ng-pg-database

This is a PostgreSQL database, configured to store
[LemonLDAP::NG](https://lemonldap-ng.org) configuration and persistent
sessions.

## Tags

* `<number>`: PostgreSQL major version
* `<number>-bookworm`: [postgres tag](https://hub.docker.com/_/postgres) used as source of this image

## Variables with default values:

* PG\_DATABASE: lemonldapng
* PG\_USER: lemonldap
* PG\_PASSWORD: lemonldap
* PG\_TABLE: lmConfig
* PG\_PERSISTENT\_SESSIONS\_TABLE: psessions
* PG\_SESSIONS\_TABLE: sessions
* PG\_SAML\_TABLE: samlsessions
* PG\_OIDC\_TABLE: oidcsessions
* PG\_CAS\_TABLE: cassessions

and all variables from postgres:bookworm. Note that you should set
`POSTGRES_PASSWORD` variable _(root password)_

## Initialize configuration

If `/llng-conf/conf.json` exists, the database will be initialized with this
configuration. You can use docker "volumes" for this:

```shell
$ docker run -v /path/to/conf.json:/llng-conf/conf.json yadd/lemonldap-ng-pg-database
```

## Initialize configuration - Remote Postgres
If you want to initialize the database in a remote Postgres Database, modify the `POSTGRES_*` variables and override the container Entrypoint. Example:
```shell
POSTGRES_HOST: postgresql.namespace.default.svc.cluster.local # Kubernetes
# POSTGRES_HOST: postgresql.us-west-2.rds.amazonaws.com # AWS RDS
# POSTGRES_HOST: postgresql.database.cloud.ovh.net # OVH Cloud
POSTGRES_PORT: 20814
POSTGRES_USER: your-admin-account
POSTGRES_DB: your-admin-db
PGPASSWORD: your-admin-password

$ docker run /docker-entrypoint-initdb.d/init-user-db.sh ---env-file=env yadd/lemonldap-ng-pg-database 
```
>Note: `PGPASSWORD` env is used by the psql client at runtime.
## Repository and bug reports

* Repository: [github.com/guimard/llng-docker](https://github.com/guimard/llng-docker/tree/master/pg)
* [Dockerfile](https://github.com/guimard/llng-docker/blob/master/pg/Dockerfile)
* [Issues database](https://github.com/guimard/llng-docker/issues)

## Copyright and license

Copyright:
 * 2018-2024, Xavier Guimard <yadd@debian.org>
 * 2023-2024, LINAGORA <https://linagora.com>

License: [GNU General Public License v2.0](https://github.com/guimard/llng-docker/blob/master/LICENSE)
