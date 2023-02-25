# Dev image

This [Dockerfile](./Dockerfile) is ready to build development images
of [LemonLDAP::NG](https://lemonldap-ng.org) using an upstream branch
_(default: `v2.0`)_

It is based on [yadd/lemonldap-ng-full](../full).

Example to build from `oidc-front-channel-logout` branch:

```shell
$ docker build -t my/test --build-arg=BRANCH=oidc-front-channel-logout .
```

## Tags

* `2.x.x-date`: base version and date of last patches included

## Copyright and license

Copyright: Xavier Guimard <yadd@debian.org>.

License: [GNU General Public License v2.0](../LICENSE)
