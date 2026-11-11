#!/bin/sh

ARGS=""
if test "$TLS_CERT_FILE"; then
	ARGS="--ssl-cert-file $TLS_CERT_FILE --ssl-key-file $TLS_KEY_FILE --enable-ssl"
fi
starman --listen=0.0.0.0:80 --workers 3 $ARGS /llng.psgi
