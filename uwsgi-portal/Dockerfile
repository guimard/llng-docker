ARG BASE=
FROM ${BASE}
LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-portal:latest-hiperf" \
      version="v1.0"

ENV SERVERNAME= \
    UWSGI_ARGS="--log-date --log-slow 1000 --log-5xx --disable-logging --master --enable-threads --vacuum --single-interpreter --perl-no-die-catch -b 65535 -l 1024 --processes=100 --cheaper=8 --auto-procname --procname-prefix-spaced=llng"

RUN echo "# Install nginx and portal libs" && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y -o Dpkg::Options::="--force-confold" --no-install-recommends install nginx \
        lemonldap-ng-uwsgi-app"${LLNGDIST}" \
        liblemonldap-ng-portal-perl"${LLNGDIST}" \
        gsfonts patch libconvert-pem-perl \
        libcrypt-u2f-server-perl libgeoip2-perl \
        libglib-perl libgssapi-perl libhttp-browserdetect-perl \
        libimage-magick-perl liblasso-perl libnet-facebook-oauth2-perl \
        libnet-openid-consumer-perl libnet-openid-server-perl \
        libnet-oauth-perl libsoap-lite-perl fonts-urw-base35 \
        libauthen-webauthn-perl libcrypt-openssl-bignum-perl \
        libconvert-base32-perl libio-string-perl libipc-run-perl \
        libgd-securityimage-perl libmime-tools-perl libnet-ldap-perl \
        libio-socket-timeout-perl libunicode-string-perl liblasso-perl \
        libio-string-perl libemail-sender-perl libregexp-common-perl \
        libcrypt-jwt-perl libdigest-hmac-perl libdata-password-zxcvbn-perl \
        libhttp-browserdetect-perl libnet-dns-perl \
        uwsgi uwsgi-plugin-psgi \
        && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY *.patch /

RUN for p in appgrid.patch jwt-type.patch app-scope.patch ignorepollers.patch \
    fixedLogout.patch more-logs.patch introspec-for-public-clients.patch \
    token-exchange.patch redirect-ajax.patch back-channel-debug.patch \
    crowdsec.patch recaptcha.patch msg-broker.patch mfe.patch \
    ; do echo patch $p && patch -p1 < $p; done && \
    rm -f /*.patch && \
    echo "# Install nginx configuration files" && \
    rm -f /etc/nginx/sites-enabled/* && \
    ln -s ../../lemonldap-ng/portal-nginx.conf /etc/nginx/sites-enabled/ && \
    (echo ""; echo "daemon off;") >> /etc/nginx/nginx.conf && \
    perl -i -pe 's#access_log .*;#access_log /dev/stdout;#; s#error_log .*;#error_log /dev/stdout info;#' /etc/nginx/nginx.conf

COPY install /

EXPOSE 80

CMD ["/usr/sbin/nginx"]
