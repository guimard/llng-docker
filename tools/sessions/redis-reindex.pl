#!/usr/bin/perl
# Usage: redis-reindex.pl [--apply] [--storage globalStorage] [--fields f1,f2]
#                         [--drop f1,f2] [--sleep MS]
#
# After a change of the Index option of a Redis session storage (default
# globalStorage):
#
# --fields: fields added to Index. Adds each stored session to the index set
#           of its current value (SADD, idempotent), as the backend does when
#           it saves a session. Default: every field of Index (unless --drop
#           is the only option).
# --drop:   fields removed from Index. Deletes their index sets. Refused for a
#           field still in Index; the sets of an indexed field sharing the
#           prefix (user_session_id_* for "user") are kept.
# --sleep:  pause between batches, in milliseconds (default 20).
#
# Sessions are never rewritten: no lost update while the portal writes. A
# session changed or deleted meanwhile may leave a stale or orphan entry:
# Web::Session::Redis's searches check the values they find and remove
# orphans; Apache::Session::Browseable::Redis doesn't, so with it rebuild only
# fields whose value doesn't change during a session (user_session_id,
# _nameID...).
#
# Without --apply, only counts. Needs Web::Session. Prints no secret.
use strict;
use warnings;
use Getopt::Long;
use JSON;
use Time::HiRes qw(time usleep);
use Web::Session::Redis;
use Web::Session::Store::Redis;

my ( $apply, $sleep, $fields, $drop, $storage ) =
  ( 0, 20, '', '', 'globalStorage' );
GetOptions(
    'apply'    => \$apply,
    'sleep=i'  => \$sleep,
    'fields=s' => \$fields,
    'drop=s'   => \$drop,
    'storage=s' => \$storage
  )
  or die
  "Usage: $0 [--apply] [--storage globalStorage] [--fields f1,f2]"
  . " [--drop f1,f2] [--sleep MS]\n";

my $conf;
if ( $ENV{SESSIONS_TOOLS_CONF} ) {    # tests: the configuration as JSON
    $conf = JSON::from_json( $ENV{SESSIONS_TOOLS_CONF} );
}
else {
    require Lemonldap::NG::Common::Conf;
    my $acc = Lemonldap::NG::Common::Conf->new( {} )
      or die "Unable to read the configuration\n";
    $conf = $acc->getConf( { cfgNum => $acc->lastCfg, noCache => 1 } );
}
# An unset storage uses globalStorage, as LemonLDAP::NG does
my $module = $conf->{$storage} || $conf->{globalStorage} // '';
my $options =
  $conf->{$storage}
  ? $conf->{"${storage}Options"}
  : $conf->{globalStorageOptions};
die "$storage is neither Web::Session::Redis nor"
  . " Apache::Session::Browseable::Redis\n"
  unless ( $module =~ /^(?:Web::Session|Apache::Session::Browseable)::Redis$/ );
print "WARNING: $module doesn't check the values found by its searches:"
  . " rebuild only fields that don't change during a session\n"
  if ( $module =~ /^Apache::Session::Browseable/ );

my $args    = { %{ $options || {} } };
my @index   = split /\s+/, ( $args->{Index} // '' );
my %indexed = map { $_ => 1 } @index;
my @todo    = $fields ? split( /,/, $fields ) : ( $drop ? () : @index );
my @drops   = $drop ? split( /,/, $drop ) : ();
for (@todo)  { die "$_ is not in Index\n"              unless $indexed{$_} }
for (@drops) { die "$_ is still in Index: not dropped\n" if $indexed{$_} }

my $redis = Web::Session::Redis->_getRedis($args);
printf "%s, %s %s, keys: %d\nrebuild: %s\ndrop: %s\n",
  $apply ? 'APPLY' : 'dry run', $storage, $module, $redis->dbsize, "@todo" || '-', "@drops" || '-';

for my $f (@drops) {
    my @other = grep { index( $_, "${f}_" ) == 0 } @index;
    my ( $cursor, $n ) = ( 0, 0 );
    do {
        my ( $next, $keys ) = $redis->scan(
            $cursor,
            MATCH => Web::Session::Redis::_globEscape($f) . '_*',
            COUNT => 1000
        );
        $cursor = $next;
        my @sets = grep {
            my $k = $_;
            !grep { index( $k, "${_}_" ) == 0 } @other
        } @$keys;
        if (@sets) {
            $n += @sets;
            $redis->unlink(@sets) if $apply;
        }

        # Every page, even without match: back-to-back SCAN calls on a large
        # database delay the portal's commands
        usleep( $sleep * 1000 ) if $sleep;
    } while ($cursor);
    printf "%-16s %d sets %s\n", $f, $n, $apply ? 'deleted' : 'to delete';
}
exit 0 unless @todo;

my ( $cursor, $sessions, $added, $next10k, %perField ) = ( 0, 0, 0, 10000 );
my $t = time;
do {
    my ( $next, $keys ) = $redis->scan( $cursor, COUNT => 500 );
    $cursor = $next;
    my @ids = grep { Web::Session::Redis->isLlngKey( $args, $_ ) } @$keys;
    if (@ids) {
        my @raw = $redis->mget(@ids);
        for my $n ( 0 .. $#ids ) {
            next unless defined $raw[$n];
            my $data = eval { Web::Session::Redis::unserialize( $raw[$n] ) };
            next unless ref $data eq 'HASH';
            $sessions++;
            for my $f (@todo) {
                my $v = $data->{$f};
                next unless ( defined $v and !ref $v and length $v );
                $perField{$f}++;
                next unless $apply;
                $added += $redis->sadd(
                    Web::Session::Store::Redis::keyName("${f}_$v"),
                    $ids[$n] );
            }
        }
        usleep( $sleep * 1000 ) if $sleep;
    }
    if ( $sessions >= $next10k ) {
        printf "  %d sessions, %d entries added, %.0fs\n", $sessions, $added,
          time - $t;
        $next10k += 10000;
    }
} while ($cursor);
printf "%d sessions; with a value: %s; %d entries %s, %.0fs\n", $sessions,
  join( ', ', map { "$_=" . ( $perField{$_} // 0 ) } @todo ), $added,
  $apply ? 'added (missing before)' : 'not added (dry run)', time - $t;
