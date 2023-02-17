FROM yadd/lemonldap-ng-portal
LABEL maintainer="Yadd yadd@debian.org>" \
	name="yadd/lemonldap-ng-full" \
	version="v1.0"

RUN echo "# Install nginx, portal and manager libs" && \
    apt -y update && \
    apt -y dist-upgrade && \
    apt -y install nginx \
    	liblemonldap-ng-manager-perl/bullseye-backports

RUN echo "Install doc" && \
    mv /etc/dpkg/dpkg.cfg.d /tmp/ && \
    apt -y install \
    	lemonldap-ng-doc/bullseye-backports && \
    mv /tmp/dpkg.cfg.d /etc/dpkg/

RUN echo "# Install nginx configuration files" && \
    cd /etc/nginx/sites-enabled/ && \
    ln -s ../../lemonldap-ng/manager-nginx.conf

COPY install /

CMD ["/usr/sbin/nginx"]
