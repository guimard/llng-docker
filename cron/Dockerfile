ARG BASE=
FROM ${BASE}

LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-cron" \
      version="v1.0"

COPY web-session-purge.patch /tmp/

RUN apt-get update && apt-get install -y cron && \
    cd /tmp/ && \
    apt-get download liblemonldap-ng-portal-perl${LLNGDIST} && \
    dpkg -x liblemonldap-ng-portal-perl*.deb portal && \
    cp portal/usr/share/lemonldap-ng/bin/purgeCentralCache /usr/share/lemonldap-ng/bin/ && \
    patch -d / -p1 < /tmp/web-session-purge.patch && rm -f /tmp/web-session-purge.patch && \
    cp portal/etc/cron.d/liblemonldap-ng-portal-perl /etc/cron.d/ && \
    rm -rf portal && \
    apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/perl5/Lemonldap/NG/Handler \
    /etc/services.d /tmp/liblemonldap-ng-portal-*

CMD ["cron", "-f"]
