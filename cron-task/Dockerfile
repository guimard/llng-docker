ARG BASE=
FROM ${BASE}

LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-cron-task" \
      version="v1.0"

ENV HANDLER_CRON=no \
    PORTAL_CRON=no

RUN apt-get update && \
    cd /tmp/ && \
    apt-get download liblemonldap-ng-portal-perl${LLNGDIST} && \
    dpkg -x liblemonldap-ng-portal-perl*.deb portal && \
    cp portal/usr/share/lemonldap-ng/bin/purgeCentralCache /usr/share/lemonldap-ng/bin/ && \
    cp portal/etc/cron.d/liblemonldap-ng-portal-perl /etc/cron.d/ && \
    rm -rf portal && \
    apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/perl5/Lemonldap/NG/Handler \
    /etc/services.d /tmp/liblemonldap-ng-portal-*

USER www-data

CMD ["/usr/share/lemonldap-ng/bin/purgeCentralCache", "-d"]
