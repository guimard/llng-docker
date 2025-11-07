FROM nginx
LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/nginx-protected"

ENV AUTHSERVER=llngauth:9001 \
    PROTECTEDHOST=test.example.com

COPY nginx/*.conf /etc/nginx/conf.d/
COPY start.sh /

RUN mkdir -p /var/cache/nginx /var/log/nginx /var/run && \
    chown -R www-data:www-data /var/cache/nginx /var/log/nginx /var/run /etc/nginx

EXPOSE 8080

USER www-data

CMD ["/start.sh"]
