ARG BASE=
FROM ${BASE}

LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-sessions-backup" \
      version="v1.0"

ENV HANDLER_CRON=no \
    PORTAL_CRON=no

COPY start.sh /backup.sh

CMD ["/backup.sh"]
