ARG BASE=
FROM ${BASE}
LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-portal" \
      version="v1.0"

ENV SERVERNAME= \
    NPROC= \
    ENGINE=FCGI

RUN echo "# Install nginx and portal libs" && \
    apt-get -y update && \
    apt-get -y upgrade && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get -y -o Dpkg::Options::="--force-confold" --no-install-recommends install nginx \
      lemonldap-ng-fastcgi-server"${LLNGDIST}" \
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
      libfcgi-engine-perl libfcgi-procmanager-maxrequests-perl \
      openssh-client \
      linagora-lemonldap-ng-store
RUN apt-get -y -o Dpkg::Options::="--force-confold" install \
      linagora-lemonldap-ng-plugin-fixed-logout-redirection \
      linagora-lemonldap-ng-plugin-json-file \
      linagora-lemonldap-ng-plugin-mail-autodiscover \
      linagora-lemonldap-ng-plugin-matrix-token-exchange \
      linagora-lemonldap-ng-plugin-oidc-acr-claims \
      linagora-lemonldap-ng-plugin-oidc-ciba \
      linagora-lemonldap-ng-plugin-oidc-device-authorization \
      linagora-lemonldap-ng-plugin-oidc-device-organization \
      linagora-lemonldap-ng-plugin-oidc-federation \
      linagora-lemonldap-ng-plugin-oidc-global-scopes \
      linagora-lemonldap-ng-plugin-oidc-grant-management \
      linagora-lemonldap-ng-plugin-oidc-jar \
      linagora-lemonldap-ng-plugin-oidc-jarm \
      linagora-lemonldap-ng-plugin-oidc-par \
      linagora-lemonldap-ng-plugin-oidc-rar \
      linagora-lemonldap-ng-plugin-oidc-resource-indicators \
      linagora-lemonldap-ng-plugin-oidc-scope-applications \
      linagora-lemonldap-ng-plugin-pacc \
      linagora-lemonldap-ng-plugin-pam-access \
      linagora-lemonldap-ng-plugin-reports \
      linagora-lemonldap-ng-plugin-ssh-ca \
      linagora-lemonldap-ng-plugin-twake \
      linagora-lemonldap-ng-plugin-vault-conf-backend \
      linagora-llng-crowdsec-filters \
      linagora-lemonldap-ng-plugin-krb-provisioning \
      open-bastion-plugins \
      && \
      rm -f /usr/bin/scp /usr/bin/sftp /usr/bin/ssh /usr/bin/ssh-add /usr/bin/ssh-agent /usr/bin/ssh-argv0 /usr/bin/ssh-copy-id /usr/bin/ssh-keyscan && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY *.patch /

RUN set -e && for p in \
    more-logs.patch \
    redirect-ajax.patch \
    getreftoken.patch \
    779-mail2f-api.patch \
    crowdsec-stats.patch \
    autoloader.patch \
    bootstrap5.patch \
    ; do echo patch $p && patch -p1 < $p || exit 1; done && \
    rm -f /usr/share/lemonldap-ng/portal/htdocs/static/common/js/carousel.min.js && \
    ln -s carousel.js /usr/share/lemonldap-ng/portal/htdocs/static/common/js/carousel.min.js && \
    cp -f /usr/share/lemonldap-ng/portal/htdocs/static/common/js/kerberosChoice.js /usr/share/lemonldap-ng/portal/htdocs/static/common/js/kerberosChoice.min.js && \
    rm -f *.patch && \
    find /usr/share/perl5/Lemonldap -name '*.orig' -delete && \
    echo "# Install nginx configuration files" && \
    rm -f /etc/nginx/sites-enabled/* && \
    ln -s ../../lemonldap-ng/portal-nginx.conf /etc/nginx/sites-enabled/ && \
    (echo ""; echo "daemon off;") >> /etc/nginx/nginx.conf && \
    perl -i -pe 's#access_log .*;#access_log /dev/stdout;#; s#error_log .*;#error_log /dev/stdout info;#' /etc/nginx/nginx.conf

COPY install /

EXPOSE 80

CMD ["/usr/sbin/nginx"]
