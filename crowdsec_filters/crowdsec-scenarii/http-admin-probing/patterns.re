# Admin interface probing detection patterns (regex)
# Based on CrowdSec http-admin-probing scenario

# Generic admin paths (must be at path boundary)
/(admin|administrator|administration|adminpanel)(/|$|\.)
/(panel|controlpanel|cpanel|dashboard)(/|$)
/(manager|management|console|backend|backoffice)(/|$)
/(sysadmin|webmaster)(/|$)

# CMS admin paths
/wp-(admin|login\.php)(/|$)
/joomla/administrator(/|$)
/drupal/admin(/|$)
/typo3(/|$)

# Database admin tools
/(phpmyadmin|pma|mysql|mysqladmin|myadmin|phpMyAdmin)(/|$)
/(phppgadmin|adminer|dbadmin|sqlmanager)(/|$|\.php)

# Server management panels
/(webmin|plesk|whm|directadmin|ispconfig|virtualmin|usermin)(/|$)

# Search and data platforms
/(solr|elasticsearch|kibana|grafana)(/|$)

# Application servers
/manager/(html|status)$
/(jmx-console|web-console)(/|$)
/(jenkins|hudson|bamboo|teamcity)(/|$)

# Monitoring and debug endpoints
/actuator(/|$)
/server-(status|info)$

# Setup/install pages
/(setup|install|installer|installation)(/|$|\.php)

# Mail admin
/(webmail|roundcube|squirrelmail|postfixadmin)(/|$)

# File managers
/(filemanager|elfinder)(/|$)

# API documentation
/(swagger|swagger-ui|api-docs|graphql|graphiql)(/|$|\.html)
