ARG BASE=
FROM ${BASE}
LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-webpubsub" \
      version="v1.0"

ENV \
    PUBSUG_ACCESS_LOG=- \
    PUBSUB_ADDR= \
    PUBSUB_CERT= \
    PUBSUB_DEBUG= \
    PUBSUB_KEY= \
    PUBSUB_MAX_REQUEST_SIZE=8192 \
    PUBSUB_MAX_REQUEST_TIME=5 \
    PUBSUB_QUIET=1 \
    PUBSUB_PORT= \
    PUBSUB_TOKEN=

CMD ["/usr/share/lemonldap-ng/bin/pubsubWebServer"]
