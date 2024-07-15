# yadd/lemonldap-ng-sessions-backup

Docker task to save all sessions into `/var/backup/lemonldap-ng`
_(to be mounted)_.

Files are named using
```shell
"/var/backup/lemonldap-ng/$(date --utc +'%F_%H:%M:%S')-sessions-backup.json"
```
