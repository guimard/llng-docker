#!/bin/sh

set -e

mkdir -p /var/backup/lemonldap-ng

FILE="/var/backup/lemonldap-ng/$(date --utc +'%F_%H:%M:%S')-sessions-backup.json"

/usr/share/lemonldap-ng/bin/lemonldap-ng-sessions \
	--user www-data \
	--group www-data \
	backup \
	> $FILE

echo "Backup in $FILE"
