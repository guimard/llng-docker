ARG BASE=
FROM ${BASE}

LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-cron" \
      version="v1.0"

RUN apt-get update && apt-get install -y cron && \
    cd /tmp/ && \
    apt-get download liblemonldap-ng-portal-perl${LLNGDIST} && \
    dpkg -x liblemonldap-ng-portal-perl*.deb portal && \
    cp portal/usr/share/lemonldap-ng/bin/purgeCentralCache /usr/share/lemonldap-ng/bin/ && \
    cp portal/etc/cron.d/liblemonldap-ng-portal-perl /etc/cron.d/ && \
    rm -rf portal && \
    apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/perl5/Lemonldap/NG/Handler \
    /etc/services.d /tmp/liblemonldap-ng-portal-*

# Note: Traditional cron daemon requires root to execute jobs as different users
# Individual cron jobs are configured to run as www-data via cron.d files
CMD ["cron", "-f"]
