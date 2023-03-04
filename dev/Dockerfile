# Build packages
ARG DEBIAN_VERSION=bullseye
FROM debian:${DEBIAN_VERSION}-slim

ARG BRANCH=v2.0

RUN apt -y update && \
    apt -y dist-upgrade && \
    apt --no-install-recommends install -y git debhelper dpkg-dev libio-string-perl libjson-perl \
        liblwp-protocol-psgi-perl libmouse-perl libregexp-assemble-perl \
        libregexp-common-perl python3-sphinx \
        python3-sphinx-bootstrap-theme \
        uglifyjs yui-compressor && \
    apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/*

WORKDIR /mnt

RUN git clone --depth 1 -b $BRANCH https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng.git llng && \
    cd llng && \
    make debian-dist && \
    mv *.orig.tar.gz* ..

RUN rm -rf llng/ && tar xzf *.orig.tar*

RUN cd lemon*/ && export DEB_BUILD_OPTIONS=nocheck && dpkg-buildpackage -d -us -uc

# Overwrite packages in image
FROM yadd/lemonldap-ng-full
LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/lemonldap-ng-dev" \
      version="v0.1"

COPY --from=0 /mnt/*.deb /tmp/

RUN apt -y update && \
    apt -y dist-upgrade && \
    dpkg --force-overwrite --force-confold -i /tmp/*.deb

RUN echo "Install doc" && \
    mv /etc/dpkg/dpkg.cfg.d /tmp/ && \
    ls -l /tmp/ && \
    dpkg --force-overwrite --force-confold -i /tmp/lemonldap-ng-doc*.deb && \
    mv /tmp/dpkg.cfg.d /etc/dpkg/

RUN rm -rf /mnt/*.deb && \
    apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/lemonldap-ng/cache && chown www-data:www-data /var/lib/lemonldap-ng/cache

CMD ["/usr/sbin/nginx"]
