FROM yadd/lemonldap-ng-base
LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-manager" \
      version="v1.0"


RUN echo "# Install nginx and manager libs" && \
    apt -y update && \
    apt -y dist-upgrade && \
    apt -y --no-install-recommends install nginx \
      lemonldap-ng-fastcgi-server${LLNGDIST} \
      liblemonldap-ng-manager-perl${LLNGDIST} \
      libglib-perl libgssapi-perl libsoap-lite-perl fonts-urw-base35 \
      libcrypt-openssl-bignum-perl libemail-sender-perl \
      libconvert-base32-perl libio-string-perl libipc-run-perl \
      libgd-securityimage-perl libmime-tools-perl libnet-ldap-perl \
      libio-socket-timeout-perl libunicode-string-perl \
      libio-string-perl && \
    mv /etc/dpkg/dpkg.cfg.d /tmp/ && \
    apt -y --no-install-recommends install \
      lemonldap-ng-doc${LLNGDIST} && \
    mv /tmp/dpkg.cfg.d /etc/dpkg/ && \
    apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/*

RUN echo "# Install nginx configuration files" && \
    cd /etc/nginx/sites-enabled/ && \
    ln -s ../../lemonldap-ng/manager-nginx.conf

RUN (echo ""; echo "daemon off;") >> /etc/nginx/nginx.conf

RUN perl -i -pe 's#access_log .*;#access_log /dev/stdout;#; s#error_log .*;#error_log /dev/stdout info;#' /etc/nginx/nginx.conf

COPY install /

EXPOSE 80

CMD ["/usr/sbin/nginx"]
