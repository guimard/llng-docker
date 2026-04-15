# Sensitive files detection patterns (regex)
# Based on CrowdSec http-sensitive-files scenario

# Environment files (anywhere in path)
/\.env($|[.~]|\.bak|\.backup|\.old|\.save|\.txt)

# Git files
/\.git(/|$)
/\.gitattributes$
/\.gitconfig$
/\.gitignore$
/\.gitmodules$

# Other VCS
/\.svn(/|$)
/\.hg($|ignore$)
/\.bzr($|/)

# Shell history and config (in any directory)
/\.(bash_history|bash_profile|bashrc|zsh_history|zshrc|profile|sh_history)$

# SSH keys and config
/\.ssh/

# Web server files
/\.ht(passwd|group|digest)$
/\.user\.ini(\.bak)?$

# Database dumps
/(database|backup|dump|db|data)\.sql(\.gz)?$

# Backup archives
/(backup|site|www)\.(tar\.gz|zip|rar)$

# Package manager files (anywhere)
/(composer|package|package-lock)\.json$
/(composer|yarn|Gemfile|Pipfile)\.lock$
/Gemfile$
/requirements\.txt$
/Pipfile$

# PHP config files
/wp-config\.php([.~]|\.bak|\.old|\.txt)?$
/wp-config-sample\.php$
/(config|configuration|settings|database|local)\.php(\.bak|\.old)?$
/settings\.local\.php$

# Framework config
/(parameters|database|secrets|credentials)\.ya?ml(\.enc)?$

# Docker and CI
/Dockerfile$
/docker-compose\.ya?ml$
/\.dockerignore$
/\.(travis|gitlab-ci)\.yml$
/Jenkinsfile$

# Cloud credentials
/\.aws/(credentials|config)$
/(credentials|service-account|firebase)\.json$
/\.firebaserc$

# Debug files
/(debug|error)\.log$
/(phpinfo|info|test)\.php$
