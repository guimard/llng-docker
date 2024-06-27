# Changes

* 2024-06-27: don't override other globalStorageOptions keys
* 2024-06-22: drop default Nginx website
* 2024-06-20: add yadd/lemonldap-ng-cron-task (v2.19.0-8)
* 2024-06-19: custom cron string
* 2024-05-29: add more debug in Back-Channel-Logout (v2.19.0-7)
* 2024-05-27: fix fixedLogout.patch (v2.19.0-6)
* 2024-05-22: add yadd/lemonldap-ng-portal-hiperf (v2.19.0-5)
* 2024-05-21: add libfcgi-engine-perl, libfcgi-procmanager-maxrequests-perl, FCGI::ProcManager::Dynamic (v2.19.0-4)
* 2024-05-14 (v2.19.0-3):
  * Add introspection patch to allow authenticated public client
  * Add OIDC token exchange (internal and Matrix), not enabled by default
* 2024-05-09: Update lemonldap-ng-pg to support external DB init (ducnm0711) (v2.19.0-2)
* 2024-05-09: More logs
* 2024-05-04: Update to 2.19.0 (v2.19.0-1), use "Overlay" configuration backend
* 2024-05-02: drop libredis-fast-perl (v2.18.2-12)
* 2024-05-01: add FixedRedirectOnLogout plugin (v2.18.2-11)
* 2024-04-26: add llngUserAttributes tool (v2.18.2-10)
* 2024-04-18: add IgnorePollers plugin (v2.18.2-9)
* 2024-04-17: add package libhttp-browserdetect-perl for Lemonldap::NG::Portal::Plugins::LocationDetect
* 2024-04-08: add `DEFAULT_WEBSITE` and `PROTECTION` env var
* 2024-04-04: add docker revision in version string
* 2024-04-03: fix cache patch
* 2024-03-27: add missing Jitsi/logout method
* 2024-03-20: add PGSSLCERT=/tmp/postgres.crt
* 2024-03-13: add patch to workaround local cache failures
* 2024-03-05: add `PG_OPTIONS` env var
* 2024-03-03: Add Jitsi support
* 2024-02-19: OIDC Auth PKCE
* 2024-02-12: 2.18.2
* 2024-01-31: Add `SERVERNAME`
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
