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
      lemonldap-ng-fastcgi-server${LLNGDIST} \
      liblemonldap-ng-manager-perl${LLNGDIST} \
      libglib-perl libgssapi-perl libsoap-lite-perl fonts-urw-base35 \
      libcrypt-openssl-bignum-perl libemail-sender-perl \
      libconvert-base32-perl libio-string-perl libipc-run-perl \
      libgd-securityimage-perl libmime-tools-perl libnet-ldap-perl \
      libio-socket-timeout-perl libunicode-string-perl \
      libio-string-perl libregexp-assemble-perl apache2-utils && \
    mv /etc/dpkg/dpkg.cfg.d /tmp/ && \
    apt-get -y --no-install-recommends install \
      lemonldap-ng-doc${LLNGDIST} && \
    mv /tmp/dpkg.cfg.d /etc/dpkg/ && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY *.patch /

RUN \
    echo patch ignorepollers.patch && patch -p1 < ignorepollers.patch && \
    echo patch fixedLogout.patch && patch -p1 < fixedLogout.patch && \
    echo patch matrix-token-exchange.patch && patch -p1 < matrix-token-exchange.patch && \
    echo patch globalLogout.patch && patch -p1 < globalLogout.patch && \
    echo patch metadata-ttl.patch && patch -p1 < metadata-ttl.patch && \
    echo patch oidc-op-claims.patch && patch -p1 <oidc-op-claims.patch && \
    echo patch improve-disconnect.patch && patch -p1 <improve-disconnect.patch && \
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
    rm -f /etc/nginx/sites-enabled/* && \
    ln -s ../../lemonldap-ng/manager-nginx.conf /etc/nginx/sites-enabled/

RUN (echo ""; echo "daemon off;") >> /etc/nginx/nginx.conf

RUN perl -i -pe 's#access_log .*;#access_log /dev/stdout;#; s#error_log .*;#error_log /dev/stdout info;#' /etc/nginx/nginx.conf

COPY install /

EXPOSE 80

CMD ["/usr/sbin/nginx"]
