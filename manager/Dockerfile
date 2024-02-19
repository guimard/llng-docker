ARG BASE=
FROM ${BASE}
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
      libio-string-perl libregexp-assemble-perl && \
    mv /etc/dpkg/dpkg.cfg.d /tmp/ && \
    apt -y --no-install-recommends install \
      lemonldap-ng-doc${LLNGDIST} && \
    mv /tmp/dpkg.cfg.d /etc/dpkg/ && \
    apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/*

COPY *.patch /

RUN echo auth-to-authn-by-jwt-manager.patch && patch -p1 < auth-to-authn-by-jwt-manager.patch && \
    echo patch anssi.patch && patch -p1 < anssi.patch && \
    echo patch oidc-auth-pkce.patch && patch -p1 < oidc-auth-pkce.patch && \
    rm -f *.patch && \
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
    rm -f /usr/share/lemonldap-ng/manager/htdocs/static/js/conftree.min.js && \
    ln -s conftree.js /usr/share/lemonldap-ng/manager/htdocs/static/js/conftree.min.js

RUN echo "# Install nginx configuration files" && \
    cd /etc/nginx/sites-enabled/ && \
    ln -s ../../lemonldap-ng/manager-nginx.conf

RUN (echo ""; echo "daemon off;") >> /etc/nginx/nginx.conf

RUN perl -i -pe 's#access_log .*;#access_log /dev/stdout;#; s#error_log .*;#error_log /dev/stdout info;#' /etc/nginx/nginx.conf

COPY install /

EXPOSE 80

CMD ["/usr/sbin/nginx"]
