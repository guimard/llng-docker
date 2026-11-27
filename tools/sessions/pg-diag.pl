#!/usr/bin/perl
# Usage: pg-diag.pl
#
# Read only (read-only transaction). PostgreSQL diagnostics of the session
# tables of the LemonLDAP::NG configuration: settings, collation, tables
# (live/dead rows, HOT updates, scans), indexes with their number of scans
# and their definition, connections, and the top statements when
# pg_stat_statements is installed. Index scans count since the last
# statistics reset (see "database stats"). Connects with the options of the
# first PostgreSQL session storage, or with PG_DSN, PG_USER and PG_PASSWORD.
# Prints no secret.
use strict;
use warnings;
use DBI;

my @storages =
  qw(globalStorage persistentStorage oidcStorage samlStorage casStorage);
my ( $dsn, $user, $pass, %tables );
if ( $ENV{PG_DSN} ) {
    ( $dsn, $user, $pass ) = @ENV{qw(PG_DSN PG_USER PG_PASSWORD)};
}
else {
    require Lemonldap::NG::Common::Conf;
    my $acc = Lemonldap::NG::Common::Conf->new( {} )
      or die "Unable to read the configuration\n";
    my $conf = $acc->getConf( { cfgNum => $acc->lastCfg, noCache => 1 } );
    for my $k (@storages) {
        my $o = $conf->{"${k}Options"} || {};
        next unless ( $conf->{$k} and ( $o->{DataSource} // '' ) =~ /^dbi:Pg/i );
        $tables{$k} = "$conf->{$k} " . ( $o->{TableName} // 'sessions' );
        ( $dsn, $user, $pass ) = @$o{qw(DataSource UserName Password)}
          unless $dsn;
    }
    die "No PostgreSQL session storage in the configuration\n" unless $dsn;
}
my $dbh = DBI->connect( $dsn, $user, $pass,
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 } );
$dbh->do('SET SESSION CHARACTERISTICS AS TRANSACTION READ ONLY');
$dbh->do("SET statement_timeout = '60s'");

sub show {
    my ( $title, $sql ) = @_;
    print "\n== $title\n";
    my $sth = eval { $dbh->prepare($sql) };
    unless ( $sth and eval { $sth->execute; 1 } ) {
        print "  (error: $DBI::errstr)\n";
        return;
    }
    print join( "\t", @{ $sth->{NAME} } ), "\n";
    while ( my $r = $sth->fetchrow_arrayref ) {
        print join( "\t", map { $_ // '' } @$r ), "\n";
    }
}

print "== storages\n";
print "$_\t$tables{$_}\n" for grep { $tables{$_} } @storages;
show( 'server', q{SELECT version()} );
show( 'collation of the database', q{SELECT datcollate, datctype
  FROM pg_database WHERE datname = current_database()} );
show( 'settings', q{SELECT name, setting, unit FROM pg_settings WHERE name IN
  ('max_connections', 'shared_buffers', 'work_mem', 'effective_cache_size',
   'autovacuum_vacuum_scale_factor', 'autovacuum_analyze_scale_factor',
   'autovacuum_vacuum_cost_limit', 'autovacuum_naptime',
   'idle_in_transaction_session_timeout', 'tcp_keepalives_idle')
  ORDER BY name} );
show( 'tables', q{SELECT c.relname, c.relpersistence AS pers,
  pg_size_pretty(pg_total_relation_size(c.oid)) AS total,
  pg_size_pretty(pg_indexes_size(c.oid)) AS indexes,
  s.n_live_tup, s.n_dead_tup, s.n_tup_upd, s.n_tup_hot_upd, s.n_tup_ins,
  s.n_tup_del, s.seq_scan, s.seq_tup_read, s.idx_scan, s.last_autovacuum,
  s.autovacuum_count
  FROM pg_class c JOIN pg_stat_user_tables s ON s.relid = c.oid
  ORDER BY pg_total_relation_size(c.oid) DESC LIMIT 20} );
show( 'indexes', q{SELECT i.relname AS tbl, i.indexrelname AS idx, i.idx_scan,
  pg_size_pretty(pg_relation_size(i.indexrelid)) AS size, x.indisvalid AS valid,
  d.indexdef
  FROM pg_stat_user_indexes i
  JOIN pg_index x ON x.indexrelid = i.indexrelid
  JOIN pg_indexes d ON d.indexname = i.indexrelname AND d.schemaname = i.schemaname
  ORDER BY 1, 3} );
show( 'connections', q{SELECT usename, application_name, state, count(*)
  FROM pg_stat_activity WHERE datname = current_database()
  GROUP BY 1, 2, 3 ORDER BY 4 DESC} );
show( 'database stats', q{SELECT numbackends, xact_commit, xact_rollback,
  blks_read, blks_hit, tup_inserted, tup_updated, tup_deleted, sessions,
  sessions_abandoned, stats_reset
  FROM pg_stat_database WHERE datname = current_database()} );
if ( $dbh->selectrow_array(
        q{SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements'}) )
{
    show( 'top statements', q{SELECT calls, round(total_exec_time) AS total_ms,
      round(mean_exec_time::numeric, 2) AS mean_ms, rows,
      regexp_replace(left(query, 160), '\s+', ' ', 'g') AS query
      FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 25} );
}
else {
    print "\n(pg_stat_statements is not installed)\n";
}
