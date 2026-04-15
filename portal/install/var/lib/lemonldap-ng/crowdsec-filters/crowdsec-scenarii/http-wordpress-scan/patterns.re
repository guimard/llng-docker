# WordPress scan detection patterns (regex)
# Based on CrowdSec http-wordpress-scan scenario

# WordPress API user enumeration
/wp-json/wp/v2/users
/wp-json/oembed

# Plugin and theme enumeration
/wp-content/(plugins|themes|uploads?)(/|$)
/wp-includes(/|$)

# Common vulnerable plugins probing
/wp-content/plugins/(revslider|gravityforms|contact-form-7)(/|$)
/wp-content/plugins/(nextgen-gallery|jetpack|woocommerce)(/|$)
/wp-content/plugins/(yoast-seo|all-in-one-seo-pack)(/|$)
/wp-content/plugins/(wp-file-manager|duplicator|wordfence)(/|$)

# Readme and changelog enumeration (version disclosure)
/wp-content/(plugins|themes)/[^/]+/(readme|changelog)\.txt$
/(readme\.html|license\.txt)$

# WordPress XML-RPC (brute force vector)
/xmlrpc\.php$

# WordPress config backup files
/wp-config\.(php[.~]|php\.(bak|old|txt|save)|old|bak|txt)$

# Debug log exposure
/wp-content/debug\.log$

# WordPress installation/upgrade files
/wp-admin/(install|setup-config|upgrade)\.php$
