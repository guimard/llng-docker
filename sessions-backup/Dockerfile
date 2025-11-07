ARG BASE=
FROM ${BASE}

LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-sessions-backup" \
      version="v1.0"

ENV HANDLER_CRON=no \
    PORTAL_CRON=no

RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install awscli && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/

COPY start.sh /backup.sh

USER www-data

CMD ["/backup.sh"]
