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
	matrix-token-exchange.patch \
        664-admin-logout.patch \
    ; do echo patch $p && patch -p1 < $p; done && \
    rm -f *.patch && \
    LLNG_DEFAULTCONFFILE=/etc/lemonldap-ng/lemonldap-ng.ini \
    perl -MLemonldap::NG::Manager::Build -e 'Lemonldap::NG::Manager::Build->run( \
      structFile   => "/usr/share/lemonldap-ng/manager/htdocs/static/struct.json", \
      confTreeFile => "/usr/share/lemonldap-ng/manager/htdocs/static/js/conftree.js", \
      managerConstantsFile => "/usr/share/perl5/Lemonldap/NG/Common/Conf/ReConstants.pm", \
      managerAttributesFile => "/usr/share/perl5/Lemonldap/NG/Manager/Attributes.pm", \
      defaultValuesFile => "/usr/share/perl5/Lemonldap/NG/Common/Conf/DefaultValues.pm", \
      confConstantsFile => "/usr/share/perl5/Lemonldap/NG/Common/Conf/Constants.pm", \
      firstLmConfFile => "/var/lib/lemonldap-ng/conf/lmConf-1.json", \
      reverseTreeFile => "/usr/share/lemonldap-ng/manager/htdocs/static/reverseTree.json", \
      handlerStatusConstantsFile => "/usr/share/perl5/Lemonldap/NG/Handler/Lib/StatusConstants.pm", \
      portalConstantsFile => "/dev/null", \
      docConstantsFile => "/dev/null", \
      )' && \
    perl -i -pe 's#^(use constant DEFAULTCONFFILE).*$#$1 => "/etc/lemonldap-ng/lemonldap-ng.ini";# && print STDERR "OK\n"' \
    	/usr/share/perl5/Lemonldap/NG/Common/Conf/Constants.pm && \
    rm -f /usr/share/lemonldap-ng/manager/htdocs/static/js/conftree.min.js && \
    ln -s conftree.js /usr/share/lemonldap-ng/manager/htdocs/static/js/conftree.min.js

RUN echo "# Install nginx configuration files" && \
    ln -s ../../lemonldap-ng/manager-nginx.conf /etc/nginx/sites-enabled/z_manager-nginx.conf

COPY install /

CMD ["/usr/sbin/nginx"]
