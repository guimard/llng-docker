# Changes

## v2.21.3-3 _(dev)_
* Fix updateConf script when value is multiline
* Improve Patroni patch
* Add device-pam
* Add `STRICT_SERVER_NAME`

## v2.21.3-2 _(2025-11-14)_
* Add Twake app-accounts plugin
* Import 3478 fix (OIDC)
* Import Patroni
* Add non-root images

## v2.21.3-1 _(2025-09-13)_
* Switch to Debian Trixie
* Switch to PostgreSQL 17
* Update to 2.21.3

## v2.21.2-3 _(2025-09-05)_
* Replace adminLogout (MR 644) by MR 722
* Patch SessionExplorer for nodes with only one dest
* Import path to fiw Google authentication (mr 777)
* Import Crowdsec enhancements (mr 784 787 797)
* add plugin Twake::Wellknown.pm
* Import 2.21.3 fix

## v2.21.2-2 _(2025-07-23)_
* Render mail2f accessible via API
* Fix Loki export in hiperf

## v2.21.2-1 _(2025-07-11)_
* Install llng client
* Launch automatically lokiSender when a loki logger is configured
* Switch to 2.21.2 (with patch due to freeze)

## v2.21.1-1 _(2025-06-17)_
* Fix introspection patch
* Add llng pub/sub server
* Switch to 2.21.1 (with patch due to freeze)

## v2.21.0-2 _(2025-04-26)_
* Fix prompt=none
* Add "aud", "iat" and "nbf" into introspection

## v2.21.0-1 _(2024-04-11)_
* Add sid in userinfo response
* Update Apache::Session::Browseable::Redis to 1.3.15
* Update to LLNG 2.21.0

## v2.20.2-3 _(2024-03-29)_
* Fix CVE-2025-31510

## v2.20.2-2 _(2024-03-27)_
* Don't use cache when getting a refresh\_token
* Improve global logout by calling portal
* Add patch for JWKS refresh
* Add login\_hint management
* Fix Forwarded-For script
* Add JSON auditLogger (enabled by default)
* Set "user" when possible in all auditLogs
* Add loki logger

## v2.20.2-1 _(2024-02-02)_
* Add "Last-Modified" header for OIDC metadata
* Add hook to modify refresh\_token
* Fix offline sessions count
* Add patch for buggy OIDC providers
* Close conf files
* Improve logs
* allow maintainance mode for portal
* Update to 2.20.2

## v2.20.1-1 _(2024-11-19)_
* Update to 2.20.1

## v2.20.0-4 _(2024-11-14)_

* Fix SAML regression
* Fix Captcha rule bug
* Add admin global logout
* Add oidcServiceMetadataTtl

## v2.20.0-3 _(2024-10-25)_
* Add ReCaptcha v3

## v2.20.0-2 _(2024-10-22)_
* Fix upstream regression on Nginx handler

## v2.20.0-1 _(2024-10-21)_
* Drop "none" from OIDC metadata
* Update to 2.20.0

## v2.19.2-1 _(2024-09-07)_
* Update to LLNG 2.19.2

## v2.19.1-5 _(2024-08-31)_
* Update to Debian 12.7

## v2.19.1-5 _(2024-08-29)(
* Add security patch (CVE-2024-45160)
* Add `_ldapsearch` command
* Add Mauritian Creole translation
* Add `LANGUAGES` variable

## v2.19.1-4 _(2024-08-19)_
* add `libconvert-pem-perl` package into portal
* add `FORWARDED_BY`
* add AUTHBASIC for manager
* add --json option to lmConfigEditor
* add message-broker

## v2.19.1-3 _(2024-08-18)_
* add `TLS_CERT_FILE` and `TLS_KEY_FILE` variables
* preserve requests in RELAY

## v2.19.1-2 _(2024-08-14)_
* add RELAY variable
* add reCaptcha plugin

## v2.19.1-1 _(2024-07-24)_
* update to 2.19.1

## v2.19.0-9 _(2024-07-15)_
* add sessions-backup task docker
* add "backup/restore" commands into session cli
* add "count" command into session cli
* update default Redis indexes
* add patch to ignore crowdsec errors
* don't override other globalStorageOptions keys
* drop default Nginx website

## v2.19.0-8 _(2024-06-20)_
* add yadd/lemonldap-ng-cron-task
* custom cron string

## v2.19.0-7 _(2024-05-29)_
* add more debug in Back-Channel-Logout

## v2.19.0-6 _(2024-05-27)_
* 2024-05-27: fix fixedLogout.patch (v2.19.0-6)

## v2.19.0-5 _(2024-05-22)_
* add yadd/lemonldap-ng-portal-hiperf

## v2.19.0-4 _(2024-05-21)_
* add libfcgi-engine-perl, libfcgi-procmanager-maxrequests-perl, FCGI::ProcManager::Dynamic

## v2.19.0-3 _(2024-05-14)_
* Add introspection patch to allow authenticated public client
* Add OIDC token exchange (internal and Matrix), not enabled by default

## v2.19.0-2 _(2024-05-09)_
* Update lemonldap-ng-pg to support external DB init (ducnm0711)
* More logs

## v2.19.0-1 _(2024-05-04)_
* Update to 2.19.0
* use "Overlay" configuration backend

## v2.18.2-12 _(2024-05-02)_
* drop libredis-fast-perl

## v2.18.2-11 _(2024-05-01)_
* add FixedRedirectOnLogout plugin

## v2.18.2-10 _(2024-04-26)_
* add llngUserAttributes tool

## v2.18.2-9 _(2024-04-18)_
* add IgnorePollers plugin
* add package libhttp-browserdetect-perl for Lemonldap::NG::Portal::Plugins::LocationDetect
* add `DEFAULT_WEBSITE` and `PROTECTION` env var
* add docker revision in version string
* fix cache patch
* add missing Jitsi/logout method
* add PGSSLCERT=/tmp/postgres.crt
* add patch to workaround local cache failures
* add `PG_OPTIONS` env var
* Add Jitsi support
* OIDC Auth PKCE

## v2.18.2 _(2024-02-12)_
* Add `SERVERNAME`
* Add patch to provide applications scope
* Add patch to fix OIDC logout when any relyong party failed
* Add fix-dropcsp.patch
* Add patches to authenticate via JWT on authn endpoint + ANSSI patch

## v2.18.1 _(2023-12-26)_
* 2023-12-06: add SAML patch to workaround Forgerock bug
* 2023-11-28: add crowdec in docs

## v2.17.2 _(2023-11-20)_
* able to redirect on unauthenticated logout
* clean reloadUrls list
* add libdbd-cassandra-perl
* add patch to fix offline/choice (#3018)
* add YAML support
* Build alternative "no-s6" and add related tags
* force create /run/llng-fastcgi-server
* improve override system (subkeys)
* import some little security fixes from 2.18.0
* add experimental LDAP support for configuration
* add override system for any Lemonldap-NG configuration key
* keep old /var/lib/lemonldap-ng/cache
* Add crowdsec parameters
* Switch to Bookworm
* JWT type
* languages API
* auth by API
* Propage env variales to FastCGI server
* revert + add appgrid.patch
* add libapache-session-mongodb-perl
* add switch "oidcDropCspHeaders"
* add libapache-session-ldap-perl
* update backlogout patch for 2.0.16+ds-4~bpo11+2
* force rebuild
