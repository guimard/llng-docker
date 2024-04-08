ARG PORTALBASE=
FROM ${PORTALBASE}
LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-full" \
      version="v1.0"

ENV PROTECTION=manager

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

COPY *.patch /

RUN echo auth-to-authn-by-jwt-manager.patch && patch -p1 < auth-to-authn-by-jwt-manager.patch && \
    echo patch anssi.patch && patch -p1 < anssi.patch && \
    echo patch oidc-auth-pkce.patch && patch -p1 < oidc-auth-pkce.patch && \
    echo patch jitsi.patch && patch -p1 < jitsi.patch && \
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
    cd /etc/nginx/sites-enabled/ && \
    ln -s ../../lemonldap-ng/manager-nginx.conf

COPY install /

CMD ["/usr/sbin/nginx"]
