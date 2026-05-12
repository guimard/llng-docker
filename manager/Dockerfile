ARG BASE=
FROM ${BASE}
LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-manager" \
      version="v1.0"

ENV PROTECTION=manager \
    AUTHBASIC=

RUN echo "# Install nginx and manager libs" && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y --no-install-recommends install nginx \
      fonts-font-awesome \
      lemonldap-ng-fastcgi-server${LLNGDIST} \
      liblemonldap-ng-manager-perl${LLNGDIST} \
      libglib-perl libgssapi-perl libsoap-lite-perl fonts-urw-base35 \
      libcrypt-openssl-bignum-perl libemail-sender-perl \
      libconvert-base32-perl libio-string-perl libipc-run-perl \
      libgd-securityimage-perl libmime-tools-perl libnet-ldap-perl \
      libio-socket-timeout-perl libunicode-string-perl \
      libio-string-perl libregexp-assemble-perl apache2-utils \
      linagora-llng-build-manager-files \
      linagora-lemonldap-ng-store
RUN apt-get -y -o Dpkg::Options::="--force-confold" install \
      linagora-lemonldap-ng-plugin-captchetat \
      linagora-lemonldap-ng-plugin-external-menu \
      linagora-lemonldap-ng-plugin-fixed-logout-redirection \
      linagora-lemonldap-ng-plugin-json-file \
      linagora-lemonldap-ng-plugin-mail-autodiscover \
      linagora-lemonldap-ng-plugin-matrix-token-exchange \
      linagora-lemonldap-ng-plugin-oidc-acr-claims \
      linagora-lemonldap-ng-plugin-oidc-device-authorization \
      linagora-lemonldap-ng-plugin-oidc-device-organization \
      linagora-lemonldap-ng-plugin-oidc-federation \
      linagora-lemonldap-ng-plugin-oidc-global-scopes \
      linagora-lemonldap-ng-plugin-oidc-grant-management \
      linagora-lemonldap-ng-plugin-oidc-jar \
      linagora-lemonldap-ng-plugin-oidc-jarm \
      linagora-lemonldap-ng-plugin-oidc-par \
      linagora-lemonldap-ng-plugin-oidc-resource-indicators \
      linagora-lemonldap-ng-plugin-oidc-scope-applications \
      linagora-lemonldap-ng-plugin-pacc \
      linagora-lemonldap-ng-plugin-pam-access \
      linagora-lemonldap-ng-plugin-reports \
      linagora-lemonldap-ng-plugin-ssh-ca \
      linagora-lemonldap-ng-plugin-twake \
      linagora-lemonldap-ng-plugin-vault-conf-backend \
      linagora-llng-crowdsec-filters \
      open-bastion-plugins \
      && \
    grep oidcRPMetaDataOptionsTokenXAuthorizedMatrix /usr/share/perl5/Lemonldap/NG/Manager/Attributes.pm && \
    mv /etc/dpkg/dpkg.cfg.d /tmp/ && \
    apt-get -y --no-install-recommends install \
      lemonldap-ng-doc${LLNGDIST} && \
    mv /tmp/dpkg.cfg.d /etc/dpkg/ && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY *.patch /

RUN set -e && for p in \
	better-cfgAuthor.patch \
	bootstrap5.patch \
	crowdsec-stats.patch \
    ; do echo patch $p && patch -p1 < $p || exit 1; done && \
    rm -f *.patch && \
    find /usr/share/perl5/Lemonldap -name '*.orig' -delete && \
    perl -i -pe 's#^(use constant DEFAULTCONFFILE).*$#$1 => "/etc/lemonldap-ng/lemonldap-ng.ini";# && print STDERR "OK\n"' \
        /usr/share/perl5/Lemonldap/NG/Common/Conf/Constants.pm && \
    perl -i -pe 's/__DNSDOMAIN__/example.com/g; s#__CACHEDIR__#/var/cache/lemonldap-ng#g; s#__SESSIONDIR__#/var/lib/lemonldap-ng/sessions#g; s#__PSESSIONDIR__#/var/lib/lemonldap-ng/psessions#g; s#__NOTIFICATIONDIR__#/var/lib/lemonldap-ng/notifications#g;' /var/lib/lemonldap-ng/conf/lmConf-1.json

COPY install /

RUN echo "Regenerating manager files (in case of patches)" && \
    mkdir -p /usr/share/perl5/Lemonldap/NG/Portal/Main/ && \
    /usr/share/lemonldap-ng/bin/lemonldap-ng-store rebuild && \
    echo "# Install nginx configuration files" && \
    rm -f /etc/nginx/sites-enabled/* && \
    ln -s ../../lemonldap-ng/manager-nginx.conf /etc/nginx/sites-enabled/ && \
    (echo ""; echo "daemon off;") >> /etc/nginx/nginx.conf && \
    perl -i -pe 's#access_log .*;#access_log /dev/stdout;#; s#error_log .*;#error_log /dev/stdout info;#' /etc/nginx/nginx.conf

EXPOSE 80

CMD ["/usr/sbin/nginx"]
