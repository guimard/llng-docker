FROM alpine:latest

LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-webpubsub" \
      version="v1.0"

ENV \
    PUBSUB_ACCESS_LOG=STDERR \
    PUBSUB_ADDR= \
    PUBSUB_CERT= \
    PUBSUB_DEBUG= \
    PUBSUB_KEY= \
    PUBSUB_MAX_REQUEST_SIZE=8192 \
    PUBSUB_MAX_REQUEST_TIME=5 \
    PUBSUB_QUIET=1 \
    PUBSUB_PORT= \
    PUBSUB_TOKEN=

RUN apk update && \
    apk upgrade && \
    apk add perl-io-socket-ssl perl-json perl-json-xs perl-protocol-websocket perl-uri && \
    apk cache clean --purge

COPY pubsubWebServer /usr/share/lemonldap-ng/bin/pubsubWebServer

CMD ["/usr/share/lemonldap-ng/bin/pubsubWebServer"]
