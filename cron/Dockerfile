FROM yadd/lemonldap-ng-base

LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-cron" \
      version="v1.0"

RUN apt update && apt install -y cron && \
    cd /tmp/ && \
    apt-get download liblemonldap-ng-portal-perl/${DEBIAN_VERSION}-backports && \
    dpkg -x liblemonldap-ng-portal-perl*.deb portal && \
    cp portal/usr/share/lemonldap-ng/bin/purgeCentralCache /usr/share/lemonldap-ng/bin/ && \
    cp portal/etc/cron.d/liblemonldap-ng-portal-perl /etc/cron.d/ && \
    rm -rf portal && \
    apt autoremove -y && apt clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/perl5/Lemonldap/NG/Handler \
    /etc/services.d

CMD ["cron", "-f"]
