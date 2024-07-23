# yadd/lemonldap-ng-sessions-backup

Docker task to save all sessions into `/var/backup/lemonldap-ng`
_(to be mounted)_.

Files are named using
```shell
"/var/backup/lemonldap-ng/$(date --utc +'%F_%H:%M:%S')-sessions-backup.json"
```

## Configuration

See [yadd/lemonldap-ng-base](https://github.com/guimard/llng-docker/blob/master/base/README.md#readme).

You can restrict the backup to a particular scope using `BACKUP` environment
variable:

* `BACKUP=persistent`: only "persistent" sessions are saved
* `BACKUP=refresh_tokens`: only OIDC refresh tokens are saved
