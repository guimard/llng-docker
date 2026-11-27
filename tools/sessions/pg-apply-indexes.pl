#!/usr/bin/perl
# Usage: pg-apply-indexes.pl [--dry-run]
#
# Runs the SQL statements after __DATA__, one at a time and in autocommit
# mode (CREATE/DROP INDEX CONCURRENTLY can't run in a transaction), then
# lists the indexes of the tables they touch. Edit the statements before use.
# A CREATE INDEX CONCURRENTLY interrupted earlier leaves an INVALID index that
# IF NOT EXISTS would keep: it is dropped and built again. Connects with the
# globalStorageOptions of the LemonLDAP::NG configuration, or with PG_DSN,
# PG_USER and PG_PASSWORD. Prints no secret.
use strict;
use warnings;
use DBI;

my $dryRun = ( @ARGV and $ARGV[0] eq '--dry-run' );
die "Usage: $0 [--dry-run]\n" if ( @ARGV and !$dryRun );

my ( $dsn, $user, $pass );
if ( $ENV{PG_DSN} ) {
    ( $dsn, $user, $pass ) = @ENV{qw(PG_DSN PG_USER PG_PASSWORD)};
}
else {
    require Lemonldap::NG::Common::Conf;
    my $acc = Lemonldap::NG::Common::Conf->new( {} )
      or die "Unable to read the configuration\n";
    my $conf = $acc->getConf( { cfgNum => $acc->lastCfg, noCache => 1 } );
    ( $dsn, $user, $pass ) =
      @{ $conf->{globalStorageOptions} }{qw(DataSource UserName Password)};
}
my $dbh = DBI->connect( $dsn, $user, $pass,
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 } );

# Waiting for a lock would block the session writes queued behind it
$dbh->do("SET lock_timeout = '30s'");

my $sql = do { local $/; <DATA> };
$sql =~ s/^\s*--.*$//mg;
my @statements = grep { /\S/ } map { s/^\s+|\s+$//gr } split /;/, $sql;
my %tables     = map { lc($_) => 1 } map { /\bON\s+(\w+)/i ? $1 : () } @statements;

my $valid = $dbh->prepare( q{SELECT i.indisvalid FROM pg_class c
  JOIN pg_index i ON i.indexrelid = c.oid
  WHERE c.relname = ? AND c.relkind = 'i'} );

sub state {
    my ($name) = @_;
    $valid->execute( lc $name );
    my ($v) = $valid->fetchrow_array;
    $valid->finish;
    return defined $v ? ( $v ? 'valid' : 'INVALID' ) : 'absent';
}

for my $st (@statements) {
    my ($idx) = $st =~ /^CREATE\s+INDEX\s+CONCURRENTLY\s+IF\s+NOT\s+EXISTS\s+(\w+)/i;
    if ( $idx and state($idx) eq 'INVALID' ) {
        print "-- $idx is INVALID (interrupted build): dropped first\n";
        $dbh->do("DROP INDEX CONCURRENTLY IF EXISTS $idx") unless $dryRun;
    }
    print "$st;\n";
    next if $dryRun;
    my $t = time;
    $dbh->do($st);
    printf "   done in %ds%s\n", time - $t, $idx ? ", $idx " . state($idx) : '';
}
print $dryRun ? "-- dry run: nothing changed\n" : "-- all statements applied\n";

my $list = $dbh->prepare( q{SELECT tablename, indexname,
  pg_size_pretty(pg_relation_size(format('%I.%I', schemaname, indexname)::regclass))
  FROM pg_indexes WHERE tablename = ANY(?) ORDER BY 1, 2} );
$list->execute( [ sort keys %tables ] );
print "\n-- indexes now:\n";
while ( my $r = $list->fetchrow_arrayref ) { print "--   @$r\n" }

__DATA__
-- Example for the tables of the pg image (sessions, psessions, oidcsessions)
-- and their default indexes, with whatToTrace = _whatToTrace. Keep the
-- indexes of the features in use: see README.md and "INDEXES FOR
-- LEMONLDAP::NG" in perldoc Web::Session::PgJSON. New indexes are created
-- before the ones they replace are dropped.

-- OpenID Connect: tokens of an SSO session (session upgrade), of a user
-- (offline tokens, manager), refresh tokens (lemonldap-ng-sessions
-- --refresh-tokens backup)
CREATE INDEX CONCURRENTLY IF NOT EXISTS o_usi ON oidcsessions ((a_session ->> 'user_session_id'));
CREATE INDEX CONCURRENTLY IF NOT EXISTS o_uid ON oidcsessions ((a_session ->> '_whatToTrace'));
CREATE INDEX CONCURRENTLY IF NOT EXISTS o_type ON oidcsessions ((a_session ->> '_type'));
DROP INDEX CONCURRENTLY IF EXISTS i_o__session_kind;

-- SSO sessions: the session explorer searches users and IP addresses by
-- prefix, which needs text_pattern_ops unless the collation is C
CREATE INDEX CONCURRENTLY IF NOT EXISTS uid1 ON sessions ((a_session ->> '_whatToTrace') text_pattern_ops);
CREATE INDEX CONCURRENTLY IF NOT EXISTS ip1 ON sessions ((a_session ->> 'ipAddr') text_pattern_ops);
DROP INDEX CONCURRENTLY IF EXISTS i_s__whattotrace;
DROP INDEX CONCURRENTLY IF EXISTS i_s_ipaddr;
-- Keep i_s_user with the password or certificate reset by mail
DROP INDEX CONCURRENTLY IF EXISTS i_s_user;
DROP INDEX CONCURRENTLY IF EXISTS i_s__httpsessiontype;

-- Persistent sessions: the persistent sessions explorer searches
-- _session_uid by prefix
CREATE INDEX CONCURRENTLY IF NOT EXISTS p_uid ON psessions ((a_session ->> '_session_uid') text_pattern_ops);
DROP INDEX CONCURRENTLY IF EXISTS i_p__session_uid;
DROP INDEX CONCURRENTLY IF EXISTS i_p__httpsessiontype;
DROP INDEX CONCURRENTLY IF EXISTS i_p_ipaddr;
DROP INDEX CONCURRENTLY IF EXISTS i_p__session_kind;
DROP INDEX CONCURRENTLY IF EXISTS i_p__whattotrace;

ANALYZE sessions;
ANALYZE psessions;
ANALYZE oidcsessions;
