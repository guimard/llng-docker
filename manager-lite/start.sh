#!/bin/sh

ARGS=""
if test "$TLS_CERT_FILE"; then
	ARGS="--ssl-cert-file $ENV{TLS_CERT_FILE} --ssl-key-file $ENV{TLS_KEY_FILE} --enable-ssl"
fi
starman --listen=0.0.0.0:8080 --workers 3 $ARGS /llng.psgi
