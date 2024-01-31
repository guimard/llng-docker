ARG BASE=
FROM ${BASE}
LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-portal" \
      version="v1.0"

ENV SERVERNAME=

RUN echo "# Install nginx and portal libs" && \
    apt -y update && \
    apt -y dist-upgrade && \
    apt -y --no-install-recommends install nginx \
        lemonldap-ng-fastcgi-server${LLNGDIST} \
        liblemonldap-ng-portal-perl${LLNGDIST} \
        gsfonts patch \
        libcrypt-u2f-server-perl libgeoip2-perl \
        libglib-perl libgssapi-perl libhttp-browserdetect-perl \
        libimage-magick-perl liblasso-perl libnet-facebook-oauth2-perl \
        libnet-openid-consumer-perl libnet-openid-server-perl \
        libnet-oauth-perl libsoap-lite-perl fonts-urw-base35 \
        libauthen-webauthn-perl libcrypt-openssl-bignum-perl \
        libconvert-base32-perl libio-string-perl libipc-run-perl \
        libgd-securityimage-perl libmime-tools-perl libnet-ldap-perl \
        libio-socket-timeout-perl libunicode-string-perl liblasso-perl \
        libio-string-perl libemail-sender-perl \
	libcrypt-jwt-perl libdigest-hmac-perl libdata-password-zxcvbn-perl && \
    apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/*

COPY *.patch /

RUN echo patch appgrid.patch && patch -p1 < appgrid.patch && \
    echo patch jwt-type.patch && patch -p1 < jwt-type.patch && \
    echo patch auth-to-authn-by-jwt-portal.patch && patch -p1 < auth-to-authn-by-jwt-portal.patch && \
    echo patch anssi.patch && patch -p1 < anssi.patch && \
    echo patch fix-dropcsp.patch && patch -p1 < fix-dropcsp.patch && \
    echo patch oidc-logout.patch && patch -p1 < oidc-logout.patch && \
    echo patch app-scope.patch && patch -p1 < app-scope.patch && \
    rm -f *.patch

RUN echo "# Install nginx configuration files" && \
    cd /etc/nginx/sites-enabled/ && \
    ln -s ../../lemonldap-ng/portal-nginx.conf

RUN (echo ""; echo "daemon off;") >> /etc/nginx/nginx.conf

RUN perl -i -pe 's#access_log .*;#access_log /dev/stdout;#; s#error_log .*;#error_log /dev/stdout info;#' /etc/nginx/nginx.conf

COPY install /

EXPOSE 80

CMD ["/usr/sbin/nginx"]
