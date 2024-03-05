ARG DEBIANVERSION=bookworm

FROM debian:${DEBIANVERSION}-slim as debian-backports-updated

ENV DEBIAN_VERSION=bookworm

RUN echo "# Install packages from ${DEBIAN_VERSION}" && \
    apt-get -y update && \
    apt-get -y install xz-utils && \
    apt-get -y dist-upgrade && \
    echo "deb http://deb.debian.org/debian" ${DEBIAN_VERSION}"-backports main" > /etc/apt/sources.list.d/backports.list && \
    apt-get -y update

FROM debian-backports-updated

ENV DEBIAN_VERSION="bookworm"
ENV LLNGDIST="/bookworm-backports"
#ENV LLNGDIST=

LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-base" \
      version="v1.0"

ENV SSODOMAIN=example.com \
    CROWDSEC_SERVER= \
    CROWDSEC_POLICY=reject \
    CROWDSEC_KEY= \
    PORTAL=http://auth.example.com/ \
    LOGLEVEL=info \
    LOGGER=stderr \
    USERLOGGER=stderr \
    REDIS_SERVER="" \
    REDIS_INDEXES="_whatToTrace _session_kind _utime ipAddr _httpSessionType _user" \
    PG_SERVER="" \
    PG_DATABASE="lemonldapng" \
    PG_USER=lemonldap \
    PG_PASSWORD=lemonldap \
    PG_TABLE=lmConfig \
    PG_PERSISTENT_SESSIONS_TABLE=psessions \
    PG_SESSIONS_TABLE=sessions \
    PG_SAML_TABLE=samlsessions \
    PG_OIDC_TABLE=oidcsessions \
    PG_CAS_TABLE=cassessions \
    PG_OPTIONS="" \
    LDAP_URL="" \
    LDAP_CONF_BASE="" \
    LDAP_CONF_DN="" \
    LDAP_CONF_PASSWORD="" \
    DBI_CHAIN="" \
    DBI_USER="" \
    DBI_PASSWORD="" \
    HANDLER_CRON=yes \
    PORTAL_CRON=yes \
    FORCE_KEY_REGENERATION=no \
    DEBIAN_FRONTEND=noninteractive

RUN echo "# Install packages from ${DEBIAN_VERSION} (${LLNGDIST})" && \
    apt-get -y --no-install-recommends install procps cron \
    liblemonldap-ng-common-perl${LLNGDIST} \
    liblemonldap-ng-handler-perl${LLNGDIST} \
    libapache-session-browseable-perl libapache-session-ldap-perl \
    libapache-session-mongodb-perl libapache-session-sqlite3-perl \
    libapache-session-wrapper-perl \
    libdbi-perl libdbd-pg-perl libnet-cidr-perl \
    libhttp-parser-xs-perl liblwp-protocol-https-perl libstring-random-perl \
    libconvert-base32-perl libnet-ldap-perl libxml-libxml-perl libxml-simple-perl \
    libdbd-cassandra-perl \
    libredis-fast-perl libredis-perl libyaml-perl libencode-perl patch && \
    apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/lib/lemonldap-ng/cache && \
    chown www-data:www-data /var/lib/lemonldap-ng/cache && \
    chmod 750 /var/lib/lemonldap-ng/cache && \
    perl -000 -MJSON -i -ne '$_=JSON::from_json($_);$_->{reloadUrls}={};print JSON->new->pretty->canonical->encode($_)' /var/lib/lemonldap-ng/conf/lmConf-1.json

#COPY syslogopt.patch .
#
#RUN patch -p1 < syslogopt.patch && rm -f syslogopt.patch && \
#    echo "# Drop comments" && \
#    perl -i -ne 'print unless /^\s*;/ or /^\s*$/' /etc/lemonldap-ng/lemonldap-ng.ini

VOLUME ["/etc/lemonldap-ng","/var/lib/lemonldap-ng/conf", "/var/lib/lemonldap-ng/sessions", "/var/lib/lemonldap-ng/psessions"]

COPY install /

COPY start /

CMD ["echo", "This is a base image, not usable directly"]

ENTRYPOINT ["./start"]
