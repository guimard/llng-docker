# yadd/lemonldap-ng-pg-database

This is a PostgreSQL database, configured to store
[LemonLDAP::NG](https://lemonldap-ng.org) configuration and persistent
sessions.

## Variables with default values:

* PG\_DATABASE: lemonldapng
* PG\_USER: lemonldap
* PG\_PASSWORD: lemonldap
* TABLE: lmConfig
* PTABLE: sessions

and all variables from postgres:bullseye. Note that you should set
`POSTGRES_PASSWORD` variable _(root password)_

## Repository and bug reports

* Repository: [github.com/guimard/llng-docker](https://github.com/guimard/llng-docker/tree/master/pg)
* [Dockerfile](https://github.com/guimard/llng-docker/blob/master/pg/Dockerfile)
* [Issues database](https://github.com/guimard/llng-docker/issues)

## Copyright and license

Copyright: Xavier Guimard <yadd@debian.org>.

License: [GNU General Public License v2.0](../LICENSE)
