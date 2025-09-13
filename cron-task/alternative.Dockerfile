ARG DEBIANVERSION=trixie

FROM debian:${DEBIANVERSION}-slim as debian-backports-updated

ENV DEBIAN_VERSION=trixie

RUN echo "# Install packages from ${DEBIAN_VERSION}" && \
    apt-get -y update && \
    apt-get -y upgrade && \
    echo "deb http://deb.debian.org/debian" ${DEBIAN_VERSION}"-backports main" > /etc/apt/sources.list.d/backports.list && \
    apt-get -y update

FROM debian-backports-updated

ENV DEBIAN_VERSION=trixie
#ENV LLNGDIST="/trixie-backports"
ENV LLNGDIST=

LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-cron" \
      version="v1.0"

WORKDIR /mnt

#RUN echo "deb-src http://deb.debian.org/debian" ${DEBIAN_VERSION}"-backports main" > /etc/apt/sources.list.d/bsrc.list && \
RUN apt-get update && \
    apt-get install -y xz-utils \
    libapache-session-browseable-perl \
    libdbi-perl libdbd-pg-perl \
    libredis-fast-perl libredis-perl \
    libnet-ldap-perl libjson-perl libjson-xs-perl \
    libmouse-perl libwww-perl liburi-perl \
    libconfig-inifiles-perl libcache-cache-perl \
    && \
    apt-get source --download-only lemonldap-ng${LLNGDIST} && \
    mkdir -p /usr/share/lemonldap-ng/bin && \
    tar xJf *.orig.tar.xz && \
    cd lemon*/ && \
    cp lemonldap-ng-portal/site/cron/purgeCentralCache /usr/share/lemonldap-ng/bin/ && \
    perl -pe 's/__APACHEUSER__/www-data/g;s@__BINDIR__@/usr/share/lemonldap-ng/bin@g' \
      < lemonldap-ng-portal/site/cron/purgeCentralCache.cron.d \
      > /etc/cron.d/liblemonldap-ng-portal-perl && \
    cp lemonldap-ng-handler/eg/scripts/purgeLocalCache /usr/share/lemonldap-ng/bin/ && \
    perl -pe 's/__APACHEUSER__/www-data/g;s@__BINDIR__@/usr/share/lemonldap-ng/bin@g' \
      < lemonldap-ng-handler/eg/scripts/purgeLocalCache.cron.d \
      > /etc/cron.d/liblemonldap-ng-handler-perl && \
    cd /mnt && \
    rm -rf * /lemon && \
    apt-get download liblemonldap-ng-common-perl${LLNGDIST} && \
    dpkg -x liblemonldap-ng-common-perl*.deb common && \
    mv common/usr/share/perl5/Lemonldap /usr/share/perl5/ && \
    rm -rf * /etc/services.d/cron && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

CMD ["cron", "-f"]
