FROM nginx
LABEL maintainer="Yadd yadd@debian.org>" \
      name="yadd/nginx-protected"

ENV AUTHSERVER=llngauth:9001 \
    PROTECTEDHOST=test.example.com

COPY nginx/*.conf /etc/nginx/conf.d/
COPY start.sh /

CMD ["/start.sh"]
