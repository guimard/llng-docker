FROM yadd/lemonldap-ng-base
LABEL maintainer="Yadd yadd@debian.org>" \
	name="lemonldap-ng-manager" \
	version="v1.0"


RUN echo "# Install nginx, portal and manager libs" && \
    apt -y update && \
    apt -y dist-upgrade && \
    apt -y install nginx \
	lemonldap-ng-fastcgi-server/bullseye-backports \
    	liblemonldap-ng-manager-perl/bullseye-backports \
    	libglib-perl libgssapi-perl libsoap-lite-perl fonts-urw-base35 \
        libcrypt-openssl-bignum-perl \
        libconvert-base32-perl libio-string-perl libipc-run-perl \
        libgd-securityimage-perl libmime-tools-perl libnet-ldap-perl \
        libio-socket-timeout-perl libunicode-string-perl \
        libio-string-perl

RUN echo "Install doc" && \
    mv /etc/dpkg/dpkg.cfg.d /tmp/ && \
    apt -y install \
    	lemonldap-ng-doc/bullseye-backports && \
    mv /tmp/dpkg.cfg.d /etc/dpkg/

RUN echo "# Install nginx configuration files" && \
    cd /etc/nginx/sites-enabled/ && \
    ln -s ../../lemonldap-ng/manager-nginx.conf

RUN (echo ""; echo "daemon off;") >> /etc/nginx/nginx.conf

COPY install /

CMD ["/usr/sbin/nginx"]
