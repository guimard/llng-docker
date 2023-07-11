FROM yadd/lemonldap-ng-portal
LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-full" \
      version="v1.0"

RUN echo "# Install nginx and portal and manager libs" && \
    apt -y update && \
    apt -y dist-upgrade && \
    apt -y --no-install-recommends install nginx \
          liblemonldap-ng-manager-perl${LLNGDIST} && \
    mv /etc/dpkg/dpkg.cfg.d /tmp/ && \
    apt -y --no-install-recommends install \
          lemonldap-ng-doc${LLNGDIST} && \
    mv /tmp/dpkg.cfg.d /etc/dpkg/ && \
    apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/*

COPY backlogout.patch .

COPY accept-mobile-url.patch .

RUN patch -p1 < backlogout.patch && rm -f backlogout.patch && \
    patch -p1 < accept-mobile-url.patch && rm -f accept-mobile-url.patch

RUN echo "# Install nginx configuration files" && \
    cd /etc/nginx/sites-enabled/ && \
    ln -s ../../lemonldap-ng/manager-nginx.conf

COPY install /

CMD ["/usr/sbin/nginx"]
