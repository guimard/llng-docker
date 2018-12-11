# LemonLDAP::NG on Nginx

## SYNOPSIS

    export PORT=8080
    docker run -p 8080:80 --env=PORT yadd/llng-nginx

## DESCRIPTION

[LemonLDAP::NG](https://lemonldap-ng.org) is a modular Web-SSO able to provide
identity provider and/or service provider for many protocols such as
OpenID-Connect, SAML, CAS. It provides an easy way to build a secured area to
protect applications with very few changes.

Lemonldap::NG manages both authentication and authorization. Furthermore
it provides headers for accounting. So you can have a full AAA protection
for your web space as described below.

## EXPORTS

Volumes:
 * `/etc/lemonldap-ng`: lemonldap-ng.ini and virtual hosts
 * `/var/lib/lemonldap-ng`: sessions and configuration files
Port:
 * 80

## BUG REPORT

Use [OW2 GitLab](https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues)
to report bug or ask for features on [LemonLDAP::NG](https://lemonldap-ng.org).

Use [GitHub](https://github.com/guimard/llng-docker/issues) to report bug or
ask features on this docker image.

## COPYRIGHT AND LICENSE

Copyright Copyright 2018, Xavier (yadd) Guimard <yadd@debian.org>

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

