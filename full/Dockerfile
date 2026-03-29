ARG PORTALBASE=
FROM ${PORTALBASE}
LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-full" \
      version="v1.0"

ENV PROTECTION=manager \
    AUTHBASIC=

RUN echo "# Install nginx and portal and manager libs" && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y --no-install-recommends install nginx \
      libnginx-mod-http-host-normalize \
      liblemonldap-ng-manager-perl${LLNGDIST} apache2-utils && \
    mv /etc/dpkg/dpkg.cfg.d /tmp/ && \
    apt-get -y --no-install-recommends install \
      lemonldap-ng-doc${LLNGDIST} && \
    mv /tmp/dpkg.cfg.d /etc/dpkg/ && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY *.patch /

RUN \
    set -e && for p in \
        ignorepollers.patch \
        fixedLogout.patch \
        722-adminlogout.patch \
	3452-sessionexplorer.patch \
	784-Crowdsec.patch \
	787-CrowdsecAgent.patch \
	797-crowdsec-agent.patch \
	twake-plugins.patch \
	dp.patch \
	875-externalMenu.patch \
	better-cfgAuthor.patch \
    ; do echo patch $p && patch -p1 < $p || exit 1; done && \
    rm -f *.patch && \
    find /usr/share/perl5/Lemonldap -name '*.orig' -delete && \
    perl -i -pe 's#^(use constant DEFAULTCONFFILE).*$#$1 => "/etc/lemonldap-ng/lemonldap-ng.ini";# && print STDERR "OK\n"' \
        /usr/share/perl5/Lemonldap/NG/Common/Conf/Constants.pm && \
    perl -i -pe 's/__DNSDOMAIN__/example.com/g; s#__CACHEDIR__#/var/cache/lemonldap-ng#g; s#__SESSIONDIR__#/var/lib/lemonldap-ng/sessions#g; s#__PSESSIONDIR__#/var/lib/lemonldap-ng/psessions#g; s#__NOTIFICATIONDIR__#/var/lib/lemonldap-ng/notifications#g;' /var/lib/lemonldap-ng/conf/lmConf-1.json && \
    rm -f /usr/share/lemonldap-ng/manager/htdocs/static/js/conftree.min.js && \
    ln -s conftree.js /usr/share/lemonldap-ng/manager/htdocs/static/js/conftree.min.js

COPY install /

RUN echo "Regenerating manager files (plugins installed in portal image)" && \
    export LLNG_DEFAULTCONFFILE=/etc/lemonldap-ng/lemonldap-ng.ini && \
    /usr/share/lemonldap-ng/bin/lemonldap-ng-store --force --plugins-dir=/etc/lemonldap-ng/manager-overrides.d rebuild && \
    grep oidcRPMetaDataOptionsTokenXAuthorizedMatrix /usr/share/perl5/Lemonldap/NG/Manager/Attributes.pm && \
    echo "# Install nginx configuration files" && \
    ln -s ../../lemonldap-ng/manager-nginx.conf /etc/nginx/sites-enabled/z_manager-nginx.conf

EXPOSE 80

CMD ["/usr/sbin/nginx"]
