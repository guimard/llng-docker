# Known web shells and backdoors
# Source: https://hub-data.crowdsec.net/web/backdoors.txt
# Patterns match filename at end of path

# C99 shell family
/c99[^/]*\.php
/c100\.php

# R57 shell family
/r57\.php
/r58\.php
/r00t\.php

# Common shell names
/shell\.php
/cmd\.php
/cmd\.asp
/cmd\.jsp
/cmdexec\.aspx
/eval-stdin\.php
/simple[_-]?cmd\.php
/simple[_-]?backdoor\.php

# File managers
/filesman\.php
/fileupload\.aspx
/filesystembrowser\.aspx
/upfile\.php
/upl0ader\.php

# WSO shells
/wso[0-9.]*\.php

# Alfa shells
/alfa[^/]*\.php

# Other known shells
/b374k\.php
/weevely\.php
/phpspy\.php
/ani-shell\.php
/antichat\.php
/locus7?s?\.php
/madshell\.php
/php-backdoor\.php
/webshell\.php
/jspshell\.jsp
/jspbd\.jsp
/aspxshell\.aspx

# Generic suspicious patterns
/[0-9]{1,4}\.php$
/xx\.php$
/x\.php$
