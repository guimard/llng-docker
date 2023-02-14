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

## Copyright and license

Copyright Xavier Guimard <yadd@debian.org>, see LICENSE file.
