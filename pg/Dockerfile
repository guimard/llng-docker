FROM postgres:bullseye

LABEL maintainer="Yadd yadd@debian.org>" \
        name="lemonldap-ng-pg-database" \
        version="v1.0"

ENV PG_DATABASE=lemonldapng \
    PG_USER=lemonldap \
    PG_PASSWORD=lemonldap \
    TABLE=lmConfig \
    PTABLE=psessions

COPY install /
