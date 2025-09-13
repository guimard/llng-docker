FROM postgres:17-trixie

LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-pg-database" \
      version="v1.0"

ENV PG_DATABASE=lemonldapng \
    PG_USER=lemonldap \
    PG_PASSWORD=lemonldap \
    PG_TABLE=lmConfig \
    PG_PERSISTENT_SESSIONS_TABLE=psessions \
    PG_SESSIONS_TABLE=sessions \
    PG_SAML_TABLE=samlsessions \
    PG_OIDC_TABLE=oidcsessions \
    PG_CAS_TABLE=cassessions

RUN mkdir -p /llng-conf

VOLUME ["/llng-conf/"]

COPY install /
