ARG BASE=
FROM ${BASE}
LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-ssoaas-fastcgi-server" \
      version="v1.0"

RUN echo "# Install libs" && \
    apt -y update && \
    apt -y dist-upgrade && \
    apt install -y --no-install-recommends \
        lemonldap-ng-fastcgi-server${LLNGDIST} \
        libfcgi-engine-perl && \
    apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/*

CMD ["/usr/sbin/llng-fastcgi-server", "--foreground", "-u", "www-data", "-g", "www-data", "-s", "/tmp/llng-fastcgi.sock", "--listen", ":9001", "-e", "FCGI::Engine"]

EXPOSE 9001
