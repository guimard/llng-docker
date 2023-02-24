#!/bin/sh

perl -i -pe 's/__AUTHSERVER__/$ENV{AUTHSERVER}/g;
s/__PROTECTEDHOST__/$ENV{PROTECTEDHOST}/g;
' /etc/nginx/conf.d/*
cat /etc/nginx/conf.d/* >&2
nginx -g "daemon off;"
