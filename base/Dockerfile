ARG DEBIANVERSION=bullseye

FROM debian:${DEBIANVERSION}-slim as debian-backports-updated

ENV DEBIAN_VERSION=bullseye

RUN echo "# Install packages from ${DEBIAN_VERSION}" && \
    apt-get -y update && \
    apt-get -y dist-upgrade && \
    echo "deb http://deb.debian.org/debian" ${DEBIAN_VERSION}"-backports main" > /etc/apt/sources.list.d/backports.list && \
    apt-get -y update

FROM debian-backports-updated

ENV DEBIAN_VERSION=bullseye

LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-base" \
      version="v1.0"

ARG S6_OVERLAY_VERSION=3.1.3.0

ENV SSODOMAIN=example.com \
    PORTAL=http://auth.example.com/ \
    LOGLEVEL=info \
    LOGGER=syslog \
    USERLOGGER=syslog \
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
    DBI_CHAIN="" \
    DBI_USER="" \
    DBI_PASSWORD="" \
    HANDLER_CRON=yes \
    PORTAL_CRON=yes \
    DEBIAN_FRONTEND=noninteractive

RUN echo "# Install packages from ${DEBIAN_VERSION}" && \
    apt-get -y --no-install-recommends install procps xz-utils cron \
    liblemonldap-ng-common-perl/${DEBIAN_VERSION}-backports \
    liblemonldap-ng-handler-perl/${DEBIAN_VERSION}-backports \
    libapache-session-browseable-perl \
    libdbi-perl libdbd-pg-perl \
    libhttp-parser-xs-perl liblwp-protocol-https-perl libstring-random-perl \
    libconvert-base32-perl libnet-ldap-perl libxml-libxml-perl libxml-simple-perl \
    libredis-fast-perl libredis-perl && \
    apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/*

RUN echo "# Drop comments" && \
    perl -i -ne 'print unless /^\s*;/ or /^\s*$/' /etc/lemonldap-ng/lemonldap-ng.ini

# S6
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/syslogd-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && rm /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && rm /tmp/s6-overlay-x86_64.tar.xz && \
    tar -C / -Jxpf /tmp/syslogd-overlay-noarch.tar.xz && rm /tmp/syslogd-overlay-noarch.tar.xz

VOLUME ["/etc/lemonldap-ng","/var/lib/lemonldap-ng/conf", "/var/lib/lemonldap-ng/sessions", "/var/lib/lemonldap-ng/psessions"]

COPY install /

# DEBUG
#CMD ["cat","/var/lib/lemonldap-ng/conf/lmConf-1.json"]

CMD ["echo", "This is a base image, not usable directly"]

ENTRYPOINT ["/init"]
