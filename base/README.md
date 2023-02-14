# yadd/lemonldap-ng-base

Base image for `yadd/lemonldap-ng-*` dockers. Does nothing except configuring
LemonLDAP::NG.

## Features

* Update current configuration using given variables :
  * set domain (`SSODOMAIN`)
  * set portal (`PORTAL`)
  * set log level (`LOGLEVEL`)
  * if `REDIS_SERVER` is set, change `globalStorage` to `Apache::Session::Browseable::Redis` and configure it _(indexes given by `REDIS_INDEXES`, default: "uid mail")_
* Upload local configuration into PostgreSQL database if:
  * `PG_SERVER` is given AND
  * PostgreSQL table is empty

## Variables and default values

* `SSODOMAIN` = example.com
* `PORTAL` = http://auth.example.com/
* `LOGLEVEL` = info
* `REDIS_SERVER` =
* `REDIS_INDEXES` = uid mail
* `PG_SERVER` =
* `PG_DATABASE` = lemonldapng
* `PG_USER` = lemonldap
* `PG_PASSWORD` = lemonldap
* `PG_TABLE` = lmConfig
* `DBI_CHAIN` = **if** `$PG_SERVER` **then** `DBI:Pg:database=$PG_DATABASE;host=$PG_SERVER` **else** `""`
* `DBI_USER` = `$PG_USER`
* `DBI_PASSWORD` = `$PG_PASSWORD`

## Copyright and license

Copyright Xavier Guimard <yadd@debian.org>, see LICENSE file.
