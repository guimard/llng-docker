ARG BASE=
FROM ${BASE}
LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-ssoaas-fastcgi-server" \
      version="v1.0"

RUN echo "# Install libs" && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
        lemonldap-ng-fastcgi-server${LLNGDIST} \
        libfcgi-engine-perl && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

CMD ["/usr/sbin/llng-fastcgi-server", "--foreground", "-u", "www-data", "-g", "www-data", "-s", "/tmp/llng-fastcgi.sock", "--listen", ":9001", "-e", "FCGI::Engine"]

EXPOSE 9001
