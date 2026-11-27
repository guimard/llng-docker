#!/usr/bin/perl
# Usage: redis-stats.pl [--storage globalStorage] [--max N]
#
# Read only. Prints the memory and the key count of the Redis database of
# the storage (default globalStorage), then the keys by kind: sessions, index sets of each field of
# Index, other keys. Walks at most N keys (default 500000). Prints no secret.
use strict;
use warnings;
use Getopt::Long;
use JSON;
use Redis;

my ( $max, $storage ) = ( 500000, 'globalStorage' );
GetOptions( 'max=i' => \$max, 'storage=s' => \$storage )
  or die "Usage: $0 [--storage globalStorage] [--max N]\n";

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
die "$storage is not a Redis backend\n" unless ( $module =~ /::Redis$/ );
my $o     = $options || {};
my @index = sort { length $b <=> length $a } split /\s+/, ( $o->{Index} // '' );

my %args = map { $_ => $o->{$_} }
  grep { /^(server|sentinels|service|password|sentinels_password|reconnect|every|name|sock)$/ }
  keys %$o;
$args{sentinels} = [ split /[\s,]+/, $args{sentinels} ]
  if ( $args{sentinels} and !ref $args{sentinels} );
my $r = Redis->new(%args);
$r->select( $o->{database} ) if defined $o->{database};

my $info = $r->info;
printf "%s, Redis %s: used_memory %s, maxmemory %s, policy %s, keys %d,"
  . " evicted %s, expired %s\n",
  "$storage $module", $info->{redis_version}, $info->{used_memory_human},
  $info->{maxmemory_human}, $info->{maxmemory_policy}, $r->dbsize,
  $info->{evicted_keys}, $info->{expired_keys};
print "Index: @index\n";

my ( $cursor, $n, %kind ) = ( 0, 0 );
do {
    my ( $next, $keys ) = $r->scan( $cursor, COUNT => 1000 );
    $cursor = $next;
    for my $k (@$keys) {

        # The longest field first: user_session_id_* is not a "user" set
        my ($f) = grep { index( $k, "${_}_" ) == 0 } @index;
        $kind{
              $k =~ /^[0-9a-f]{32,}$/ ? 'session'
            : $f                      ? "index $f"
            : $k =~ /^(_?[^_]+_)/      ? "other $1*"
            :                           'other'
        }++;
    }
    $n += @$keys;
} while ( $cursor and $n < $max );
printf "%s %d keys:\n", ( $cursor ? 'first' : 'all' ), $n;
printf "  %-28s %d\n", $_, $kind{$_}
  for sort { $kind{$b} <=> $kind{$a} } keys %kind;
