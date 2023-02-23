# Build packages
FROM debian:bullseye-slim

ARG BRANCH=v2.0

RUN apt -y update && \
    apt -y dist-upgrade && \
    apt install -y git debhelper dpkg-dev libio-string-perl libjson-perl \
        liblwp-protocol-psgi-perl libmouse-perl libregexp-assemble-perl \
        libregexp-common-perl python3-sphinx \
        python3-sphinx-bootstrap-theme \
        uglifyjs yui-compressor

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

RUN dpkg --force-overwrite --force-confold -i /tmp/*.deb

RUN mkdir -p /var/lib/lemonldap-ng/cache && chown www-data:www-data /var/lib/lemonldap-ng/cache

CMD ["/usr/sbin/nginx"]