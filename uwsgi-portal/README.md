# yadd/lemonldap-ng-portal:latest-hiperf

High performance version of [yadd/lemonldap-ng-portal](https://github.com/guimard/llng-docker/blob/master/portal/README.md#readme)
based on [uWSGI](https://uwsgi-docs.readthedocs.io/en/latest/).

Configuration is the same than [yadd/lemonldap-ng-portal](https://github.com/guimard/llng-docker/blob/master/portal/README.md#readme)
except that variables related to [Plack](https://metacpan.org/pod/Plack) engine
are replaced by:

 * `UWSGI_ARGS`: the arguments to give to **uWSGI** daemon. Default:
   `--log-date --log-slow 1000 --log-5xx --disable-logging --master --enable-threads --vacuum --single-interpreter --perl-no-die-catch -b 65535 -l 1024`

## Repository and bug reports

* Repository: [github.com/guimard/llng-docker](https://github.com/guimard/llng-docker/tree/master/portal)
* [Dockerfile](https://github.com/guimard/llng-docker/blob/master/portal/Dockerfile)
* [Issues database](https://github.com/guimard/llng-docker/issues)

## Copyright and license

Copyright:
 * 2018-2024, Xavier Guimard <yadd@debian.org>
 * 2023-2024, LINAGORA <https://linagora.com>

License: [GNU General Public License v2.0](https://github.com/guimard/llng-docker/blob/master/LICENSE)

