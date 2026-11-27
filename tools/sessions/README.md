# Session storage tools

Maintenance scripts for the session storages of a LemonLDAP::NG deployment
using these images: Redis index sets, PostgreSQL indexes. They are not
installed in the images.

## Running them

Each script reads the LemonLDAP::NG configuration of the container it runs
in, so it uses the session backend, the server and the credentials of the
deployment. Run it from a portal container, through its standard input:

```shell
kubectl exec -i <portal-pod> -- perl - [options] < tools/sessions/<script>
docker exec -i <portal-container> perl - [options] < tools/sessions/<script>
```

- They print counts and sizes, never a secret nor a session content.
- Without `--apply`, a script that changes something only prints what it
  would do (`pg-apply-indexes.pl`: `--dry-run`).
- `redis-clean-orphans.pl` and `redis-reindex.pl` need Web::Session
  (`libweb-session-perl`), installed in the images since 2.23.4-12 and
  2.21.6-13. Elsewhere, copy its `lib` into the container and add
  `-I<dir>` after `perl`.
- `SESSIONS_TOOLS_CONF` (Redis scripts, `verify-index.pl`) replaces the
  configuration by a JSON document, for tests.

| Script                   | Storage    | Changes                       |
| ------------------------ | ---------- | ----------------------------- |
| `redis-stats.pl`         | Redis      | nothing                       |
| `redis-clean-orphans.pl` | Redis      | index members (`--apply`)     |
| `redis-reindex.pl`       | Redis      | index sets (`--apply`)        |
| `verify-index.pl`        | any        | nothing                       |
| `pg-diag.pl`             | PostgreSQL | nothing                       |
| `pg-apply-indexes.pl`    | PostgreSQL | indexes (without `--dry-run`) |

## Redis

With a Redis `globalStorage`, every field listed in the `Index` option has
one set per value (`<field>_<value>`) holding the ids of the sessions with
that value. A search on a field which is not in `Index` reads every
session.

### What to index

Index only the fields that LemonLDAP::NG searches with the enabled
features:

| Field             | Searched by                                                |
| ----------------- | ---------------------------------------------------------- |
| `_whatToTrace`    | session explorer, CheckUser, global logout, single session |
| `_session_kind`   | session explorers                                          |
| `ipAddr`          | session explorer by IP address, `singleIP`                 |
| `_session_uid`    | trusted browser, persistent sessions                       |
| `user_session_id` | OpenID Connect: tokens of an SSO session (session upgrade) |
| `user`, `mail`    | password or certificate reset by mail                      |
| `_oidcRtUpdate`   | purge of the refresh tokens with `RtActivity`              |
| any               | `checkUserSearchAttributes`, REST session server `search`  |

The SAML searches go to `samlStorage` when it is set, with the `Index` of
`samlStorageOptions` (another database may hold these sessions):

| Field        | Searched by                                               |
| ------------ | --------------------------------------------------------- |
| `ProxyID`    | **every SAML authentication response** (request restored) |
| `_saml_id`   | SAML sessions of an SSO session (logout)                  |
| `_nameID`    | SAML logout initiated by the other party                  |
| `_assert_id` | SAML assertions                                           |
| `_art_id`    | artifact binding                                          |

A searched field missing from `Index` makes every such search read the
whole database: without `ProxyID`, each SAML login reads every SAML session
and index set, and a large database saturates the portals. Check the code of
the LemonLDAP::NG version in use before removing a field.

`_utime` is useless: the purge reads every session anyway, and this index
costs one set per session plus two writes on every session update.
`_httpSessionType` is never searched.

### Orphan entries

`Apache::Session::Browseable::Redis` before 1.3.19 deleted the expired
sessions without removing them from their index sets: these sets keep the
ids of deleted sessions forever, and the searches read them. 1.3.19 and
Web::Session remove them on purge; Web::Session also removes those that its
searches meet. To clean the ones already stored:

```shell
... perl - < tools/sessions/redis-stats.pl                    # before
... perl - < tools/sessions/redis-clean-orphans.pl            # plan
... perl - --apply < tools/sessions/redis-clean-orphans.pl    # every field
... perl - --apply _whatToTrace < tools/sessions/redis-clean-orphans.pl
```

It only removes members whose session doesn't exist, with the same atomic
check as Web::Session's searches: it can run while the portal works. It
takes a few minutes per field for tens of thousands of sessions.

### Changing `Index`

Redis doesn't build an index from the stored sessions: a set is only
written when a session is saved. So:

- **Removing a field** is safe: the searches on it read every session. Its
  sets stay in Redis until they are deleted.
- **Adding a field** is not: the searches use the new index at once, and
  miss every session stored before, without error, until each one is saved
  again.

Procedure, once the new `Index` is deployed on every container (an older
container still writes the sets of the removed fields):

```shell
# fields added: count, then add the stored sessions to their sets
... perl - --fields user_session_id,_nameID < tools/sessions/redis-reindex.pl
... perl - --apply --fields user_session_id,_nameID < tools/sessions/redis-reindex.pl
# fields removed: delete their sets
... perl - --drop _utime,_httpSessionType < tools/sessions/redis-reindex.pl
... perl - --apply --drop _utime,_httpSessionType < tools/sessions/redis-reindex.pl
# check
... perl - user_session_id _nameID _whatToTrace < tools/sessions/verify-index.pl
```

- `redis-reindex.pl` never rewrites a session: a refresh token or an
  offline session is never lost or changed. Run twice, the second run adds
  nothing.
- Until the rebuild is over, a search on an added field can miss a session
  stored before the change (for `_nameID`: a logout from the identity
  provider which doesn't close that session).
- `Apache::Session::Browseable::Redis` doesn't check the values found by its
  searches: with it, rebuild only fields whose value doesn't change during a
  session. Web::Session checks them.
- A field name may be the prefix of another one (`user` and
  `user_session_id`): `--drop user` keeps the sets of an indexed field. Check
  with `verify-index.pl` afterwards anyway.

### Checking an index

`verify-index.pl` compares, for each value, the result of `searchOn()` with a
full read of the storage. `missing` means an index lacking entries,
`unexpected` stale entries; a few of them come from sessions created or
deleted while it runs. It makes one search per distinct value: allow several
minutes for tens of thousands of sessions. `--storage oidcStorage` checks
another storage.

## PostgreSQL

`pg-diag.pl` prints the tables (live and dead rows, HOT updates), the
indexes with their number of scans since the last statistics reset, the
collation and the connections. `pg-apply-indexes.pl` applies the statements
written after its `__DATA__` line: edit them first. The recommended indexes
are in "INDEXES FOR LEMONLDAP::NG" in `perldoc Web::Session::PgJSON`.

- An index is only used by a query with the very same expression:
  `a_session ->> 'field'`, or `cast(a_session ->> 'field' as bigint)` for
  `_utime` and the other numbers.
- With a collation other than `C`, a plain index can't serve a prefix search
  (`LIKE 'abc%'`, used by the session explorers): create it with
  `text_pattern_ops`, which serves both equality and prefixes. An index with
  0 scans may be unusable rather than useless.
- Session updates are never HOT with expression indexes on `a_session`:
  every index costs on every update. Drop the unused ones.
- `CREATE INDEX CONCURRENTLY` doesn't block the writes but can't run in a
  transaction, and an interrupted build leaves an `INVALID` index:
  `pg-apply-indexes.pl` runs each statement on its own and rebuilds such an
  index.
- The backup of the OpenID Connect refresh tokens
  (`lemonldap-ng-sessions --refresh-tokens backup`) searches `_type`: index
  `a_session ->> '_type'` on the OpenID Connect table.
