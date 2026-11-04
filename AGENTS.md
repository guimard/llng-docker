# How this repository works

Guide for agents (human or AI) who need to modify, debug or ship an image from
this repository.

## 0. In one sentence

This repository **does not build LemonLDAP::NG from [source](https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng)**: it builds Docker
images from the [**Debian packages** of LemonLDAP::NG](https://tracker.debian.org/pkg/lemonldap-ng), adds the **[Linagora
plugins](https://linagora.github.io/lemonldap-ng-plugins/)**, and applies **backport patches** for features or fixes that are not
yet in the Debian version being used.

Practical consequence: you will not find the LLNG source code here. You will
find Dockerfiles, initialization scripts, patches and the publishing
configuration.

---

## 1. The two release branches

The two branches to know are `master` and `lts-2.21`. Other branches (`exp`,
`experimental`, `gh-pages`, work branches) may exist: do not use them as a
release base.

| Topic                                     | `master`                                         | `lts-2.21`                                              |
| ----------------------------------------- | ------------------------------------------------ | ------------------------------------------------------- |
| Role                                      | Current 2.23.x line                              | 2.21.x LTS, supported until 2030                        |
| Debian base                               | Debian 13 `trixie` + `trixie-backports`          | Debian 13 `trixie` stable                               |
| LLNG packages                             | `LLNGDIST=/trixie-backports`                     | `LLNGDIST=` (packages from `trixie`)                    |
| Version in the workflow                   | `VERSION=2.23.4`, `DOCKERREVISION=6`             | `VERSION=2.21.6`, `DOCKERREVISION=7`                    |
| Latest tag when this document was written | `v2.23.4-5`                                      | `v2.21.6-7`                                             |
| Public Docker tags                        | `latest`, version, version-trixie, suffixes      | `lts-2.21`, `stable`, version, version-trixie, suffixes |
| Helm channel                              | `helm/latest`                                    | `helm/lts-2.21`                                         |
| Linagora plugins                          | Full stack (store + Debian packages)             | Minimal: mostly `lang-mn`                               |
| Manager                                   | Manager API, `new-manager`, `bootstrap5` skin    | Classic manager, plus `manager-lite/`                   |
| Patches                                   | `2.23.3.patch`, `2.23.4.patch` + feature patches | `2.21.5.patch` + patches named after MRs/issues         |

The version values above are indicative: the **source of truth** is the `env:`
block of `.github/workflows/docker-publish.yml` on the branch in question.

### 1.1 Why two branches?

- `lts-2.21` tracks the version that Debian stable supports until 2030. It is
  deliberately kept close to vanilla LLNG, with few plugins, to minimize risk.
- `master` tracks the newer version through `trixie-backports` and carries the
  full Linagora stack (OIDC plugins, Open Bastion, new manager, etc.).
- `stable` is a Docker alias for the last LTS _(`lts-2.21` for now)_, not for
  `master`.

### 1.2 Flow between branches

There is no single automatic flow. In practice:

1. many fixes are first produced or backported on `lts-2.21`;
2. `master` then merges `lts-2.21` (`Merge branch 'lts-2.21'`);
3. but `master` also has its own patches and features, which do **not**
   automatically flow down to the LTS.

So: never assume that a merge is enough. Before considering a feature present
in both branches, check the diff and the `for p in ...` loop of the relevant
Dockerfile.

Patches are **branch-specific**: paths, Perl versions and LLNG APIs differ
between 2.21 and 2.23. A patch from `master` almost never applies as-is to
`lts-2.21`, and vice versa.

### 1.3 Versioning, tags and releases

The git tag name must be exactly:

```
v${VERSION}-${DOCKERREVISION}
```

Example: `VERSION=2.23.4` and `DOCKERREVISION=6` require the tag
`v2.23.4-6`. The `check-tag` job rejects the whole pipeline if the pushed tag
does not match. This is intentional: images and the Helm chart are versioned
from these variables, not from the tag name.

#### How to read a tag

A tag reads as `<LLNG base>-<Docker revision>`:

- `2.23.4` is the LemonLDAP::NG version the image is functionally based on.
  It is usually the Debian package version, but it can also be a version
  reconstituted by applying patches to an older Debian package: what matters
  is the LLNG behavior actually embedded in the image, not the package version
  alone.
- `6` is the Docker revision: the 6th published state built on that LLNG
  base. It is not a patch number and not "the 6th patch"; it increments for
  any change to the image (new patch, Debian rebuild, plugin update,
  configuration change, etc.).
- Therefore `2.23.4-6` means "6th image release based on LemonLDAP::NG
  2.23.4", not "LemonLDAP::NG 2.23.4.6" and not a Debian package revision
  such as `+deb13u4`.

Examples:

- `2.23.4-5` -> `2.23.4-6`: same LLNG base, one more Docker revision.
- `2.23.3-3` -> `2.23.4-1`: new LLNG base, the revision counter starts again
  at 1.
- `2.21.6-7`: 7th image release based on LLNG 2.21.6.

Rules:

- a new release = bump `DOCKERREVISION` (and `VERSION` when the LLNG version
  changes) + an entry in `Changes.md` + a git tag;
- never move an existing tag: bump the revision instead;
- even a simple Debian rebuild (package updates) deserves a new revision,
  because the published images change.

On every push to a release branch, CI also publishes `latest` images (master)
or `YYYY-MM-DD-lts` images (LTS) and date tags on master. Version tags and the
Helm chart are published only on a `v*` tag.

---

## 2. Where components come from

### 2.1 Debian stable and backports

Images start from `debian:trixie-slim`. The Dockerfiles add:

```text
deb http://deb.debian.org/debian trixie-backports main
```

Regular Debian packages (nginx, `liblasso-perl`, `libnet-ldap-perl`,
PostgreSQL 17, etc.) come from `trixie` stable. Only LLNG packages use the
`${LLNGDIST}` suffix.

### 2.2 LemonLDAP::NG: Debian source, not upstream source

The `liblemonldap-ng-*-perl`, `lemonldap-ng-fastcgi-server`,
`lemonldap-ng-uwsgi-app` and `lemonldap-ng-doc` packages come from the Debian
repositories. Their Debian source is maintained by the Debian Perl Team on
Salsa:

<https://salsa.debian.org/perl-team/modules/packages/lemonldap-ng>

branch `trixie` (with the backports variant used by `master`).

So the flow is:

```text
upstream LLNG (GitLab) / Salsa Debian
        -> Debian package (trixie or trixie-backports)
        -> APT repository
        -> Docker image built by this repository
```

This repository only intervenes at the last step, plus the catch-up patches.

- `lts-2.21`: `ENV LLNGDIST=` → packages from `trixie` stable (2.21.x).
- `master`: `ENV LLNGDIST="/trixie-backports"` → newer packages (2.23.x)
  from `trixie-backports`.

Do not "fix" `LLNGDIST` on the LTS to use backports: that would change the LLNG
version and therefore the support contract.

### 2.3 Linagora plugins and Open Bastion

The additional plugins come from:

<https://github.com/linagora/lemonldap-ng-plugins>

That repository publishes:

- a **store** `lemonldap-ng-store`: `https://linagora.github.io/lemonldap-ng-plugins/`;
- a **Debian repository**: `https://linagora.github.io/lemonldap-ng-plugins/debian stable main`;
- helper packages (`linagora-llng-build-manager-files`,
  `linagora-llng-crowdsec-filters`, etc.).

The `portal`, `uwsgi-portal` and `manager` Dockerfiles install the
`linagora-lemonldap-ng-plugin-*` packages directly. `full` inherits the portal
stack and adds `new-manager`.

**Four plugins come from Open Bastion**:

- `pam-access`;
- `ssh-ca`;
- `oidc-device-authorization`;
- `oidc-device-organization`.

Their source code lives in
<https://github.com/linagora/open-bastion>, under `llng/plugins/`.
They reach `lemonldap-ng-plugins` through the **git submodule `open-bastion`**
declared in that plugins repository's `.gitmodules`, then are published like
the other packages.

Important point: **`llng-docker` contains no submodule**. The submodule
relationship is upstream, in `lemonldap-ng-plugins`. Here, we only consume
already-published Debian packages.

The full plugin stack is mostly installed on `master`. The `lts-2.21` branch
stays minimal (mainly `lang-mn`); do not add the Open Bastion stack there
without an explicit decision.

### 2.4 Other components

- **S6 overlay**: `just-containers/s6-overlay`, version pinned by
  `ARG S6_OVERLAY_VERSION` in `base/Dockerfile`.
- **`llng` OIDC client**: archive from `linagora/simple-oidc-client`, copied
  to `/usr/local/lib`.
- **PostgreSQL**: `postgres:17-trixie` image for `pg/`.
- **Pub/Sub**: Alpine image for `webpubsub/`.
- **Bundled Perl modules**: `DBD::Patroni`, `Apache::Session::Browseable`
  and other modules are copied directly into
  `base/install/usr/share/perl5/`.
- **`dev/`**: exception, this image clones and builds LLNG from the upstream
  GitLab repository (`BRANCH`, default `v2.0`). It is not a release image.
- **`lemonldap-ng.list`**: historical upstream LLNG repository file, not used
  by the current Dockerfiles.

### 2.5 Reference links

These links provide context; they are **not** the source of truth for this
repository. Always inspect the local Dockerfiles, patches and workflow `env:`
first.

| Link                                                                                                                                          | Use it for                                                                                   | Do not use it for                                                       |
| --------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| [LLNG upstream (GitLab)](https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng)                                                                    | finding a commit/MR to backport, understanding an upstream feature                           | assuming the upstream source layout matches the Debian-installed layout |
| [Debian package tracker](https://tracker.debian.org/pkg/lemonldap-ng)                                                                         | checking the Debian version, CVEs and upload history                                         | reading the actual source code                                          |
| [Debian Salsa, `trixie` branch](https://salsa.debian.org/perl-team/modules/packages/lemonldap-ng)                                             | Debian source, Debian packaging patches, exact package content                               | Linagora-specific patches and plugin integration                        |
| [Linagora plugins source](https://github.com/linagora/lemonldap-ng-plugins)                                                                   | plugin code, issues, activation rules, the Open Bastion submodule                            | the exact package version installed in an image                         |
| [Linagora plugin store](https://linagora.github.io/lemonldap-ng-plugins/)                                                                     | checking whether a feature already exists as a plugin and how to activate it                 | the source of truth for plugin code                                     |
| [Linagora Debian repository](https://linagora.github.io/lemonldap-ng-plugins/debian)                                                          | package names and published versions consumed by the Dockerfiles                             | replacing a local patch without checking the image                      |
| [Open Bastion](https://github.com/linagora/open-bastion)                                                                                      | source of `pam-access`, `ssh-ca`, `oidc-device-authorization` and `oidc-device-organization` | the publication channel of the plugins                                  |
| [Docker Hub `yadd`](https://hub.docker.com/u/yadd)                                                                                            | published image tags and digests                                                             | build or patch behavior                                                 |
| [Helm `latest`](https://guimard.github.io/llng-docker/helm/latest) and [Helm `lts-2.21`](https://guimard.github.io/llng-docker/helm/lts-2.21) | published chart versions                                                                     | image source code                                                       |

Notes:

- an upstream LLNG fix is useful input, but this repository patches the
  **Debian-installed files**: run the upstream patch through `./transform` and
  adapt it before adding it;
- external branches and URLs move. The authoritative LLNG version is the
  `VERSION` value in `.github/workflows/docker-publish.yml`, and the
  authoritative installed package is whatever the Dockerfile installs;
- when a link and the local files disagree, the local files win.

---

## 3. Repository map

| Path                             | Purpose                                                   |
| -------------------------------- | --------------------------------------------------------- |
| `base/`                          | LLNG base image, S6, shared config, `base` patches        |
| `base-no-s6/`                    | Same without S6; patches identical to `base/`             |
| `portal/`                        | nginx + FastCGI portal, plugins, portal patches           |
| `uwsgi-portal/`                  | "hiperf" uWSGI portal; patches identical to `portal/`     |
| `manager/`                       | nginx + FastCGI manager, plugins, manager patches         |
| `full/`                          | Portal + Manager in one image; manager patches            |
| `pg/`                            | Pre-initialized PostgreSQL 17 for LLNG                    |
| `cron/`                          | LLNG maintenance task runner                              |
| `cron-task/`                     | Runs one maintenance task and exits                       |
| `sessions-backup/`               | Backs up sessions and exits                               |
| `ssoaas-fastcgi-server/`         | FastCGI server for SSOaaS                                 |
| `webpubsub/`                     | Alternative Pub/Sub server                                |
| `dev/`                           | Development image from upstream sources                   |
| `no-root/`                       | Overlay to produce `-non-root` variants                   |
| `helm/`                          | Helm chart (manager, portal, cronjob)                     |
| `.github/workflows/`             | Build, tests, Docker and Helm publishing                  |
| `.github/actions/docker-common/` | Composite build/publish action                            |
| `build-all`                      | Local build and test of all images                        |
| `transform`                      | Converts an upstream patch to the Debian installed layout |
| `Changes.md`                     | Version changelog, to update on every change              |
| `README.md`, `*/README.md`       | User documentation, pushed to Docker Hub                  |

Each image README is also published as the Docker Hub description. Update it
when adding an environment variable or changing behavior.

---

## 4. Build chain

Logical order:

```text
pg (independent)
webpubsub (independent, Alpine)

base
 ├── portal ──── full
 │      └────── uwsgi-portal (-hiperf variant)
 ├── manager
 ├── cron
 ├── cron-task
 ├── sessions-backup
 └── ssoaas-fastcgi-server

base-no-s6
 └── same images, -no-s6 suffix

no-root/Dockerfile: builds FROM an already published image,
                     to produce the -non-root tags
```

`full` is not based directly on `base`: it is based on the `portal` image via
the `PORTALBASE` argument, then adds the manager.

`build-all` builds in this order:

```text
pg base manager portal uwsgi-portal full ssoaas-fastcgi-server
cron cron-task sessions-backup webpubsub
```

It also checks that duplicated patches are identical:

- `base/*.patch` == `base-no-s6/*.patch`;
- `portal/*.patch` == `uwsgi-portal/*.patch`;
- `manager/*.patch` == `full/*.patch`;
- some manager/full installation files are compared byte for byte.

If those checks fail, the build stops. This is expected: copies must stay in
sync.

---

## 5. What each image does

### `base`

- installs the LLNG packages and Perl dependencies;
- installs S6 overlay (except in `base-no-s6`);
- copies the `llng` OIDC client;
- applies the `base/*.patch` patches;
- forces the `Overlay` configuration backend;
- initializes default values and the cache/session directories;
- exposes `/etc/lemonldap-ng`, `/var/lib/lemonldap-ng/conf`,
  `/var/lib/lemonldap-ng/sessions`, `/var/lib/lemonldap-ng/psessions`.

The `/etc/cont-init.d/update-llng-conf` script (run by S6, or by `/start` in
no-s6) does the following:

- enables `Overlay`;
- enables `useServerEnv=1`;
- sets `LOGLEVEL`, loggers, Loki and the audit logger;
- creates LLNG command symlinks in `/usr/bin`;
- handles `SSODOMAIN`, `PORTAL`, `REDIS_SERVER`, `PG_SERVER`, etc.

Default variable values are in the `ENV` block of `base/Dockerfile`. The
`base/` README documents them.

### `portal` and `uwsgi-portal`

- nginx + `lemonldap-ng-fastcgi-server` (or uWSGI);
- installs the Linagora plugin stack;
- portal patches;
- nginx configuration generated in `/etc/nginx/sites-enabled`;
- `portal` exposes port 80, `uwsgi-portal` is tagged `-hiperf`.

### `manager` and `full`

- nginx + manager;
- `manager` installs the full Linagora plugin stack, including `new-manager`
  on master;
- `full` inherits the portal plugin stack, adds the manager, then installs
  `new-manager` after the patches;
- manager patches, then rebuild of the manager files
  (`struct.json`, `conftree.js`, `Attributes.pm`, etc.) via
  `lemonldap-ng-store rebuild`;
- `full` enables `PROTECTION=manager`.

### Variants

- `-no-s6`: same image without S6, entrypoint `/start` runs the init scripts
  then the services.
- `-non-root`: `no-root/Dockerfile` starts from an existing image, chowns the
  required directories, replaces port 80 with 8080 and switches to
  `USER www-data`.
- `-hiperf`: uWSGI portal.

---

## 6. The patch system

This is the most important and most fragile part of the repository.

### 6.1 Why patches?

The Debian packages contain a frozen version of LLNG. Linagora needs:

- upstream fixes not yet released in the Debian version;
- features from newer LLNG versions backported;
- Linagora-specific needs (Manager API, SAML, CrowdSec, peering, plugins,
  etc.);
- security fixes (CVEs) ahead of the Debian release.

Rather than rebuilding the Debian packages, the repository applies diffs
directly to the files installed by those packages, inside the Docker image.

### 6.2 Where patches live and how they are applied

Patches live in the directory of the relevant image:

```text
base/*.patch
base-no-s6/*.patch       (copy of base/)
portal/*.patch
uwsgi-portal/*.patch     (copy of portal/)
manager/*.patch
full/*.patch             (copy of manager/)
```

They are copied to `/` with `COPY *.patch /`, then applied in the Dockerfile:

```dockerfile
RUN set -e && for p in \
    patch1.patch \
    patch2.patch \
    ; do echo patch $p && patch -p1 < $p || exit 1; done
```

Their internal paths therefore look like:

```text
a/usr/share/perl5/Lemonldap/NG/...
b/usr/share/lemonldap-ng/portal/...
```

and not `lemonldap-ng-portal/lib/...`. This is the key point to understand
before writing a patch.

### 6.3 Patch families

1. **Version patches**: `2.23.3.patch`, `2.23.4.patch` on master;
   `2.21.5.patch` on the LTS.
   They import the changes from the previous LLNG version to the target
   version, split by component (`base`, `portal`, `manager`, `full`). They
   must be regenerated on every LLNG update.

2. **Upstream backports**: features or fixes taken from a newer version or a
   GitLab MR. The header often contains
   `Upstream: https://gitlab.ow2.org/...`.
   Examples: `ldap-filter-escape.patch` (MR !1113), `ppolicy.patch`
   (backport !1117), `adminlogout-hashed.patch`, `oidc-rfc-compliance.patch`,
   `manager-api-*.patch`.

3. **Linagora-specific needs**: features or settings specific to Linagora,
   sometimes with no upstream equivalent: `saml-idp-api.patch`,
   `samlStrictIdpSelection.patch`, `crowdsec-stats.patch`,
   `mn-translations.patch`, `new-manager` integration, etc.

4. **Operational fixes**: `fix-mail-mime.patch`, `msg-broker-pg.patch`,
   `crowdsec-onreload.patch`, `conf-cache.patch` (LTS), etc.

5. **Older patches named after MRs/issues** (mostly on `lts-2.21`):
   `708-sid-in-userinfo.patch`, `717-introspection.patch`,
   `718-iat-and-nbf-in-at.patch`, `722-adminlogout.patch`,
   `779-mail2f-api.patch`, `874-geoip.patch`, `875-externalMenu.patch`,
   `3452-sessionexplorer.patch`, etc.
   On master, many of them have been replaced by store plugins or folded into
   the version patches.

Policy: **if a feature already exists as a plugin/store entry, prefer the
plugin over a patch**. Patches must remain the exception, not become a fork.

### 6.4 Application order and plugin interaction

The order of the `for p in ...` loop matters. Do not sort it alphabetically.

Sensitive points on master:

- manager patches are applied **before** installing the plugins;
- installing a plugin triggers a rebuild of the manager files through dpkg
  triggers;
- that rebuild must happen on pristine manager files, hence the order:
  LLNG packages -> patches -> plugins -> `lemonldap-ng-store rebuild`;
- `linagora-llng-build-manager-files` is patched in the image to fix its Perl
  library path (`/usr/share/perl5`);
- `lemonldap-ng-store rebuild` regenerates the manager metadata with the
  plugin attributes;
- the `grep oidcRPMetaDataOptionsTokenXAuthorizedMatrix` is a non-regression
  check: if the line is missing, the rebuild did not take effect.

On the LTS there is no store: the manager is rebuilt by a direct Perl call to
`Lemonldap::NG::Manager::Build->run(...)`.

### 6.5 The `transform` script

`./transform` reads an upstream patch on stdin and rewrites it for the
installed layout:

- `lemonldap-ng-common/lib/...` -> `usr/share/perl5/...`;
- `lemonldap-ng-portal/site/...` -> `usr/share/lemonldap-ng/portal/...`;
- `lemonldap-ng-*/scripts/...` -> `usr/share/lemonldap-ng/bin/...`;
- drops unnecessary files (tests, `debian/`, docs, Makefile, etc.).

Example:

```bash
./transform < /tmp/upstream.patch > portal/my-backport.patch
```

Always review the result: `transform` does not know about
repository-specific patches and may leave unsuitable paths.

### 6.6 Common pitfalls

- **Do not patch generated manager files** (`struct.json`, `conftree.js`,
  `Attributes.pm`, `reverseTree.json`, etc.): they are regenerated. Patch the
  Perl source or the templates instead.
- **Do not copy a patch between branches** without adapting it: paths and
  APIs change.
- **Do not forget the copies**: a portal patch must also be in
  `uwsgi-portal/`; a manager patch must also be in `full/`.
- **Do not break the order**: a patch that depends on another must come after
  it.
- **Do not leave `.orig` files**: the Dockerfiles delete them, but a badly
  applied patch can create them.
- **A patch must be minimal and documented**: an `Upstream:` header when
  applicable, otherwise a comment explaining the Linagora need.
- **Delete obsolete patches** as soon as the Debian version or a plugin
  includes them. Update `Changes.md` accordingly.

---

## 7. Operational recipes

### 7.1 Adding a patch

1. Check out the right branch and identify the LLNG version.
2. Reproduce the problem in a container based on the real image (not on
   upstream sources).
3. Modify the installed file, then generate a diff with `a/usr/...` /
   `b/usr/...` paths.
4. If the patch comes from upstream, run it through `./transform`.
5. Add an `Upstream:` header or an explanatory comment.
6. Put the patch in **all** relevant directories.
7. Add it to the `for p in ...` loop of the relevant Dockerfile(s), in the
   right place.
8. Build and test the image.
9. Add an entry to `Changes.md`.

Example of diff generation:

```bash
# inside a container, after modifying files:
diff -Nur /tmp/orig/usr /usr > /tmp/my.patch
# then rewrite the headers to a/usr and b/usr
```

### 7.2 Removing a patch

1. Verify that the Debian version or the plugin now provides the behavior.
2. Remove the line from the `for p in ...` loop.
3. Delete the file from all copies.
4. Rebuild and check that the associated non-regression test passes.
5. Update `Changes.md`.

### 7.3 Updating LemonLDAP::NG

1. Check the version available in `trixie` or `trixie-backports`.
2. Update `VERSION` in `.github/workflows/docker-publish.yml`.
3. Regenerate the version patches (`2.x.y.patch`) by comparing installed
   files between the old and new versions, split by component.
4. Rebase or remove feature patches that are no longer needed.
5. Check the application order and conflicts.
6. Update `Changes.md`, bump `DOCKERREVISION`.
7. Run `./build-all` (or at least the impacted images).
8. Tag `v${VERSION}-${DOCKERREVISION}` and push the tag.

### 7.4 Updating plugins

Plugins are not pinned in the Dockerfiles: a rebuild picks up the latest
version published in the Linagora APT repository. To integrate a new version:

1. check the announced compatibility (see `COMPAT-open-bastion.md` and
   `UPGRADING.md` in `lemonldap-ng-plugins`);
2. rebuild the impacted images;
3. if the rebuild changes no tracked file, trigger the workflow manually
   (`workflow_dispatch`);
4. update `Changes.md` and bump `DOCKERREVISION` to publish clean tags.

### 7.5 Debian security rebuild

When Debian publishes updates (nginx, ImageMagick, tzdata, etc.):

1. rebuild;
2. check the tests;
3. bump `DOCKERREVISION`;
4. document the updated packages in `Changes.md`;
5. tag.

A rebuild must never reuse an existing tag.

---

## 8. Local build and tests

Prerequisites: Docker and Docker Compose.

Full build (long):

```bash
./build-all
```

Build only a few images:

```bash
LIST="base portal" ./build-all
```

`build-all` builds with:

```text
BASE=yadd/lemonldap-ng-base:latest
PORTALBASE=yadd/lemonldap-ng-portal:latest
```

So you must build `base` before `portal`, and `portal` before `full`.

Tests:

- `build-all` runs `./test` in each image that has one, except `full`;
- tests use `docker compose` in the `__test__` directories;
- `base/test` checks the generated configuration (DBI, Redis, Overlay,
  languages, etc.);
- `portal/test`, `manager/test`, `full/test` and `dev/test` check application
  behavior.

To test a single image:

```bash
cd portal
./test
```

`DEBUG=yes ./build-all` disables the duplicated-patch consistency checks. Use
it locally only, never to validate a release.

---

## 9. CI/CD and publishing

### 9.1 Workflows

| File                                   | Trigger                                               | Purpose                                                       |
| -------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------- |
| `.github/workflows/docker-publish.yml` | push to the release branch + `v*` tags                | check-tag, full build/test, image build/push, Helm publishing |
| `.github/workflows/pr.yml`             | push to work branches (`workflow_dispatch` on master) | `./build-all`                                                 |
| `.github/workflows/trivy.yml`          | after the publish workflow + weekly                   | vulnerability scan                                            |
| `.github/workflows/hadolint.yml`       | master push/PR + weekly                               | Dockerfile lint                                               |

`docker-publish.yml` runs:

1. `check-tag`: the tag must match `v${VERSION}-${DOCKERREVISION}`;
2. `test`: `./build-all`;
3. build and push of each image, with job dependencies (base before
   portal/manager, portal before full);
4. `publish-helm` only on tags, after the `-no-s6` images.

The `.github/actions/docker-common` composite action handles:

- buildx and QEMU;
- Docker Hub login;
- tags;
- multi-arch on tags (`amd64`, `arm64`, `arm/v7`, `s390x`);
- `-no-s6` and `-non-root` variants;
- updating the image README on Docker Hub.

### 9.2 Release checklist

1. `Changes.md` up to date, unreleased section turned into a dated version.
2. `VERSION` and `DOCKERREVISION` up to date in the branch workflow.
3. `helm/Chart.yaml` and `helm/values.yaml` consistent (the workflow adjusts
   image tags at publish time).
4. `./build-all` green.
5. Commit pushed.
6. Tag `v${VERSION}-${DOCKERREVISION}` pushed.
7. Check the CI jobs and the Helm publication.
8. Check the Docker Hub tags (`latest` or `lts-2.21`/`stable`).

### 9.3 Helm

The chart lives in `helm/`. It deploys:

- the portal (`-no-s6-hiperf` by default);
- the manager (`-no-s6`);
- the maintenance cronjob (`-no-s6`).

It is published on GitHub Pages:

- `https://guimard.github.io/llng-docker/helm/latest` for master;
- `https://guimard.github.io/llng-docker/helm/lts-2.21` for the LTS.

Publishing happens on the `gh-pages` branch. The workflow:

1. aligns the image tags in `helm/values.yaml` with the release;
2. `helm dependency build`;
3. `helm package` with `--version ${VERSION}` and
   `--app-version ${VERSION}-${DOCKERREVISION}`;
4. copies the archive and updates `index.yaml` on `gh-pages`.

The chart is **not** published on a simple branch push, only on a tag.

---

## 10. Golden rules for an agent

1. **Identify the branch and LLNG version before any modification.**
   `master` and `lts-2.21` do not have the same packages, patches or plugins.
2. **Work on the files installed by Debian**, not on an upstream clone. A
   patch must apply with `patch -p1` inside the image.
3. **Prefer a plugin/store entry over a new patch** when the feature already
   exists.
4. **Keep copies in sync**: `base`/`base-no-s6`, `portal`/`uwsgi-portal`,
   `manager`/`full`.
5. **Respect the patch order** and the order patches -> plugins -> manager
   rebuild.
6. **Do not edit generated manager files.**
7. **Test with `./build-all`** or at least the impacted image.
8. **Update `Changes.md`** and the image README when behavior changes.
9. **Never move a tag**: increment `DOCKERREVISION`.
10. **Do not publish from a work branch**: the release CI only runs on
    `master` or `lts-2.21` and on tags.
11. **Check `git status`**: the repository may contain untracked local scripts
    (`cleanup-old-tags.sh`, `retag-stable.sh`) that are not part of CI.

---

## 11. Cheat sheet

```bash
# Show the branch version and revision
sed -n '1,10p' .github/workflows/docker-publish.yml

# Show an image's patches and their order
grep -n -A30 'for p in' portal/Dockerfile

# Show the installed plugin list
grep -n 'linagora-lemonldap-ng-plugin' portal/Dockerfile

# Convert an upstream patch
./transform < upstream.patch > portal/feature.patch

# Local build
LIST="base portal" ./build-all

# Check duplicated patches (same check as build-all)
diff <(cd base && md5sum *.patch | sort) \
     <(cd base-no-s6 && md5sum *.patch | sort)
diff <(cd portal && md5sum *.patch | sort) \
     <(cd uwsgi-portal && md5sum *.patch | sort)
diff <(cd manager && md5sum *.patch | sort) \
     <(cd full && md5sum *.patch | sort)

# Show the latest releases
git tag --sort=-creatordate | head -20

# Check a tag before pushing it
git tag -l "v${VERSION}-${DOCKERREVISION}"
```

---

## 12. Mental summary

```text
Debian trixie (stable) + trixie-backports (master)
        |
        +-- LLNG packages (Debian Salsa source, trixie branch)
        +-- Linagora plugin packages (4 of them from Open Bastion)
        |
        v
Dockerfiles (base -> portal/manager -> full)
        |
        +-- version patches / backports / Linagora-specific needs
        +-- S6 init scripts or /start
        |
        v
yadd/lemonldap-ng-* images + Helm chart
        |
        v
Docker Hub (latest or lts-2.21/stable) + GitHub Pages (helm)
```

If a change does not clearly fit this scheme, it often belongs upstream
(Debian, `lemonldap-ng-plugins`, `open-bastion`) rather than in this
repository.
