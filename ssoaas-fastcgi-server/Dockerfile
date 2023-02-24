FROM yadd/lemonldap-ng-base
LABEL maintainer="Yadd yadd@debian.org>" \
	name="yadd/lemonldap-ng-ssoaas-fastcgi-server" \
	version="v1.0"

RUN echo "# Install nginx, portal and manager libs" && \
    apt -y update && \
    apt -y dist-upgrade && \
    apt install -y --no-install-recommends \
        lemonldap-ng-fastcgi-server/bullseye-backports \
        libfcgi-engine-perl

CMD ["/usr/sbin/llng-fastcgi-server", "--foreground", "-u", "www-data", "-g", "www-data", "-s", "/tmp/llng-fastcgi.sock", "--listen", ":9001", "-e", "FCGI::Engine"]

EXPOSE 9001
