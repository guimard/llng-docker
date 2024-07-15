#!/bin/sh

set -e

mkdir -p /var/backup/lemonldap-ng

FILE="/var/backup/lemonldap-ng/$(date --utc +'%F_%H:%M:%S')-sessions-backup.json"
OPTS='--user www-data --group www-data'

if test "$BACKUP" == "persistent"; then
	OPTS="$OPTS --persistent"
elif test "$BACKUP" == "refresh_tokens"; then
	OPTS="$OPTS --refresh-tokens"
fi

/usr/share/lemonldap-ng/bin/lemonldap-ng-sessions \
	$OPTS \
	backup \
	> $FILE

echo "Backup in $FILE"
