ARG BASE=
ARG DEBIAN_VERSION=bookworm
FROM ${BASE}
LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-webpubsub" \
      version="v1.0"

FROM debian:${DEBIAN_VERSION}-slim

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

COPY --from=0 /usr/share/lemonldap-ng/bin/pubsubWebServer /usr/share/lemonldap-ng/bin/pubsubWebServer

RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get --no-install-recommends install -y perl-base libio-socket-ssl-perl libjson-perl libjson-xs-perl libprotocol-websocket-perl liburi-perl && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

CMD ["/usr/share/lemonldap-ng/bin/pubsubWebServer"]
