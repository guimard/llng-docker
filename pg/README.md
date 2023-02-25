# yadd/lemonldap-ng-pg-database

This is a PostgreSQL database, configured to store
[LemonLDAP::NG](https://lemonldap-ng.org) configuration and persistent
sessions.

## Tags

* `<number>`: PostgreSQL major version
* `<number>-bullseye`: [postgres tag](https://hub.docker.com/_/postgres) used as source of this image

## Variables with default values:

* PG\_DATABASE: lemonldapng
* PG\_USER: lemonldap
* PG\_PASSWORD: lemonldap
* TABLE: lmConfig
* PTABLE: sessions

and all variables from postgres:bullseye. Note that you should set
`POSTGRES_PASSWORD` variable _(root password)_

## Initialize configuration

If `/llng-conf/conf.json` exists, the database will be initialized with this
configuration. You can use docker "volumes" for this:

```shell
$ docker run -v /path/to/conf.json:/llng-conf/conf.json yadd/lemonldap-ng-pg-database
```

## Repository and bug reports

* Repository: [github.com/guimard/llng-docker](https://github.com/guimard/llng-docker/tree/master/pg)
* [Dockerfile](https://github.com/guimard/llng-docker/blob/master/pg/Dockerfile)
* [Issues database](https://github.com/guimard/llng-docker/issues)

## Copyright and license

Copyright: Xavier (Yadd) Guimard <yadd@debian.org>.

License: [GNU General Public License v2.0](https://github.com/guimard/llng-docker/blob/master/LICENSE)
