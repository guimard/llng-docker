# Guide : Proteger une application web locale avec LemonLDAP::NG

Ce dossier contient tout le necessaire pour tester LemonLDAP::NG (LLNG) en
tant que SSO devant une application web locale.

## Architecture

```
                       Port 80
                         |
                    [ HAProxy ]
                    /    |     \
                   /     |      \
  auth.example.com  manager.example.com  myapp.example.com
        |                |                     |
   [ Portal LLNG ]  [ Manager LLNG ]   [ Nginx + App ]
        |                |                     |
        +-------+--------+             [ authserver ]
                |                      (FastCGI LLNG)
         [ PostgreSQL ]                      |
         [   Redis    ]              +-------+-------+
                                     |               |
                                [ PostgreSQL ]  [  Redis  ]
```

**Composants :**
- **HAProxy** : point d'entree unique, route selon le nom de domaine
- **Portal LLNG** : portail d'authentification (login)
- **Manager LLNG** : interface d'administration
- **authserver** : serveur FastCGI qui verifie les sessions pour proteger votre app
- **myapp** : votre application web, protegee par Nginx + le handler LLNG
- **PostgreSQL** : stocke la configuration LLNG
- **Redis** : stocke les sessions utilisateur

## Prerequis

- Docker et Docker Compose installes
- Ports 80 disponible sur votre machine

## Etape 1 : Configurer le DNS local

Ajoutez ces lignes dans votre fichier `/etc/hosts` (Linux/Mac) ou
`C:\Windows\System32\drivers\etc\hosts` (Windows) :

```
127.0.0.1   auth.example.com
127.0.0.1   manager.example.com
127.0.0.1   myapp.example.com
```

## Etape 2 : Demarrer la stack

```bash
cd test/
docker compose up -d --build
```

Attendez environ 30 secondes que tous les services demarrent.

Verifiez que tout tourne :

```bash
docker compose ps
```

## Etape 3 : Se connecter au portail

Ouvrez votre navigateur et allez sur :

```
http://auth.example.com/
```

**Identifiants par defaut :**
- Login : `dwho`
- Mot de passe : `dwho`

> LemonLDAP::NG est livre avec des utilisateurs de demo :
> - `dwho` / `dwho` (Doctor Who - administrateur)
> - `rtyler` / `rtyler` (Rose Tyler - utilisateur standard)
> - `msmith` / `msmith` (Mickey Smith - utilisateur standard)

## Etape 4 : Acceder a l'application protegee

Apres authentification, allez sur :

```
http://myapp.example.com/
```

Si vous n'etes pas authentifie, vous serez automatiquement redirige vers
le portail de login.

## Etape 5 : Administrer LLNG via le Manager

Accedez au Manager pour configurer les regles d'acces :

```
http://manager.example.com/
```

> Connectez-vous d'abord sur le portail avec `dwho` (qui a les droits admin).

### Declarer votre application dans le Manager

Par defaut, LLNG autorise l'acces a `*.example.com`. Pour personaliser :

1. Allez dans **Virtual Hosts** dans le Manager
2. Cliquez sur **Add virtual host**
3. Entrez `myapp.example.com`
4. Configurez les **Rules** :
   - Regle par defaut : `accept` (tout le monde authentifie peut acceder)
   - Ou ajoutez des regles specifiques par URL (ex: `^/admin` -> `$uid eq "dwho"`)
5. Configurez les **Headers** pour transmettre des infos a votre app :
   - `Auth-User` -> `$uid`
   - `Auth-Mail` -> `$mail`
   - `Auth-Name` -> `$cn`
6. Sauvegardez la configuration

## Proteger votre propre application

### Option A : Application statique (HTML/CSS/JS)

Remplacez simplement le contenu du dossier `sample-app/` par vos fichiers,
puis reconstruisez :

```bash
docker compose up -d --build myapp
```

### Option B : Application sur un autre port (Node.js, Python, PHP...)

Si votre app tourne deja localement (ex: `localhost:3000`), modifiez le
fichier `nginx/handler-nginx.conf` pour ajouter un proxy vers votre app :

```nginx
location / {
    set $original_uri $uri$is_args$args;
    auth_request /lmauth;
    auth_request_set $lmremote_user $upstream_http_lm_remote_user;
    auth_request_set $lmlocation $upstream_http_location;
    error_page 401 $lmlocation;

    # Proxy vers votre application locale
    proxy_pass http://host.docker.internal:3000;
    proxy_set_header Host $host;
    proxy_set_header Auth-User $lmremote_user;
}
```

Puis dans `docker-compose.yml`, ajoutez a `myapp` :

```yaml
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

### Option C : Ajouter un conteneur applicatif existant

Si votre app est deja containerisee, ajoutez-la au `docker-compose.yml` :

```yaml
  monapp-backend:
    image: mon-image:latest
    # ou build: ./mon-app
```

Puis modifiez `nginx/handler-nginx.conf` pour proxyer vers ce conteneur :

```nginx
    proxy_pass http://monapp-backend:8080;
```

Et ajoutez le backend dans `haproxy/haproxy.cfg` si besoin.

## Structure des fichiers

```
test/
  docker-compose.yml          # Orchestration de tous les services
  Dockerfile.nginx-protected   # Image Nginx avec le handler LLNG
  start.sh                     # Script de demarrage Nginx
  nginx/
    handler-nginx.conf         # Config Nginx : auth_request vers LLNG
  haproxy/
    haproxy.cfg                # Routage par nom de domaine
  sample-app/
    index.html                 # Application de demo
  GUIDE.md                     # Ce fichier
```

## Commandes utiles

```bash
# Demarrer
docker compose up -d --build

# Voir les logs
docker compose logs -f

# Logs d'un service specifique
docker compose logs -f portal
docker compose logs -f myapp

# Redemarrer un service
docker compose restart myapp

# Tout arreter
docker compose down

# Tout arreter et supprimer les donnees
docker compose down -v
```

## Depannage

### "502 Bad Gateway" sur myapp.example.com
Le serveur d'authentification n'est pas encore pret. Attendez quelques
secondes et reessayez.

### Boucle de redirection infinie
Verifiez que `myapp.example.com` est bien dans `/etc/hosts` et pointe
vers `127.0.0.1`.

### Le portail affiche une erreur
Verifiez les logs : `docker compose logs -f portal`

### Je ne peux pas me connecter
Les identifiants par defaut sont `dwho` / `dwho`. LLNG utilise une base
de demo interne.

### L'application ne recoit pas les headers utilisateur
Configurez les **Headers** dans le Manager (Virtual Hosts > myapp.example.com
> Headers) pour transmettre `$uid`, `$mail`, etc.
