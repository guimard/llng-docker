# Changes

* 2024-03-27: add missing Jitsi/logout method
* 2024-03-20: add PGSSLCERT=/tmp/postgres.crt
* 2024-03-13: add patch to workaround local cache failures
* 2024-03-05: add `PG_OPTIONS` env var
* 2024-03-03: Add Jitsi support
* 2024-02-19: OIDC Auth PKCE
* 2024-02-12: 2.18.2
* 2024-01-31: Add SERVERNAME
* 2024-01-11: Add patch to provide applications scope
* 2024-01-11: Add patch to fix OIDC logout when any relyong party failed
* 2024-01-08: Add fix-dropcsp.patch
* 2023-12-26: Add patches to authenticate via JWT on authn endpoint + ANSSI patch
* 2023-12-26: 2.18.1
* 2023-12-06: add SAML patch to workaround Forgerock bug
* 2023-11-28: add crowdesc in docs
* 2023-11-20: 2.17.2
* 2023-10-23: able to redirect on unauthenticated logout
* 2023-10-17: clean reloadUrls list
* 2023-10-10: add libdbd-cassandra-perl
* 2023-09-28: add patch to fix offline/choice (#3018)
* 2023-09-18: add YAML support
* 2023-09-18: Build alternative "no-s6" and add related tags
* 2023-09-15: force create /run/llng-fastcgi-server
* 2023-09-12: improve override system (subkeys)
* 2023-09-08:
  * import some little security fixes from 2.18.0
  * add experimental LDAP support for configuration
  * add override system for any Lemonldap-NG configuration key
* 2023-09-06: keep old /var/lib/lemonldap-ng/cache
* 2023-09-05: Add crowdsec parameters
* 2023-09-01: Switch to Bookworm
* 2023-08-28: JWT type
* 2023-07-25: languages API
* 2023-07-21: auth by API
* 2023-07-13: Propage env variales to FastCGI server
* 2023-07-10: revert + add appgrid.patch
* 2023-07-05: add libapache-session-mongodb-perl
* 2023-06-28: add switch "oidcDropCspHeaders"
* 2023-05-23: add libapache-session-ldap-perl
* 2023-05-15: update backlogout patch for 2.0.16+ds-4~bpo11+2
* 2023-04-28: force rebuild
