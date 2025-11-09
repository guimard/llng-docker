ARG IMAGE=
FROM ${IMAGE}

RUN \
	for d in /run /etc/lemonldap-ng /var/lib/nginx/ /var/backup/; do \
		echo "############# ${d}" >&2; \
		if test -e ${d}; then chown -R www-data ${d}; fi; \
	done; \
	if test -e /etc/cont-init.d/; then perl -i -pe 's/\b80\b/8080/' /etc/cont-init.d/*; fi && \
	for i in `find /usr/share/lemonldap-ng/bin -type f -perm -g=x`; do \
		NAME=`basename ${i}`; \
		test -e /usr/bin/${NAME} || ln -s $i /usr/bin/${NAME}; \
	done; \
	echo Errors ignored

USER www-data
