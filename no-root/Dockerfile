ARG IMAGE=
FROM ${IMAGE}

RUN \
	chown -R www-data /run; \
	chown -R www-data /etc/lemonldap-ng; \
	chown -R www-data /var/lib/nginx/; \
	chown -R www-data /var/backup/; \
	perl -i -pe 's/\b80\b/8080/' /etc/cont-init.d/* && \
	for i in `find /usr/share/lemonldap-ng/bin -type f -perm -g=x`; do \
		NAME=`basename $$i`; \
		test -e /usr/bin/$$NAME || ln -s $i /usr/bin/$$NAME; \
	done

USER www-data
