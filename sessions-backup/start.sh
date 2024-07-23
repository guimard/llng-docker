#!/bin/sh

set -e

mkdir -p /var/backup/lemonldap-ng

FILE="/var/backup/lemonldap-ng/$(date --utc +'%F_%H:%M:%S')-sessions-backup"
OPTS='--user www-data --group www-data'

if test "$BACKUP" == "persistent"; then
	OPTS="$OPTS --persistent"
	FILE="$FILE-persistent"
elif test "$BACKUP" == "refresh_tokens"; then
	OPTS="$OPTS --refresh-tokens"
	FILE="$FILE-oidc-refresh-tokens"
fi
FILE="$FILE.json"

/usr/share/lemonldap-ng/bin/lemonldap-ng-sessions \
	$OPTS \
	backup \
	> $FILE

echo "Backup in $FILE"
