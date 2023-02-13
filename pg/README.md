# yadd/lemonldap-ng-pg-database

This is a PostgreSQL database, configured to store
[LemonLDAP::NG](https://lemonldap-ng.org) configuration.

## Variables with default values:

* PG\_DATABASE: lemonldapng
* PG\_USER: lemonldap
* PG\_PASSWORD: lemonldap
* TABLE: lmConfig

and all variables from postgres:bullseye. Note that you should set
`POSTGRES_PASSWORD` variable _(root password)_
