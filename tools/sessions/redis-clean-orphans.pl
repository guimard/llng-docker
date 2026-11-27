#!/usr/bin/perl
# Usage: redis-clean-orphans.pl [--apply] [--storage globalStorage]
#                               [--sleep MS] [field...]
#
# Removes from the Redis index sets of the storage (default globalStorage)
# the members whose session no longer exists, for the given fields (default:
# every field of Index). Each orphan is removed with Web::Session::Redis's
# atomic EXISTS + SREM, as its searches do: a session written meanwhile is
# kept, and a set losing its last member disappears. Sessions are only read.
# The sets of an indexed field sharing the prefix (user_session_id_* for
# "user") are skipped.
#
# --sleep: pause after each page of 1000 sets, in milliseconds (default 20):
#          on a large database, back-to-back pages delay the portal's
#          commands.
#
# Without --apply, only counts the orphans. Needs Web::Session. Prints no
# secret.
use strict;
use warnings;
use Getopt::Long;
use JSON;
use Time::HiRes qw(time usleep);
use Web::Session::Redis;

$| = 1;
my ( $apply, $storage, $sleep ) = ( 0, 'globalStorage', 20 );
GetOptions( 'apply' => \$apply, 'storage=s' => \$storage, 'sleep=i' => \$sleep )
  or die "Usage: $0 [--apply] [--storage globalStorage] [--sleep MS]"
  . " [field...]\n";

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
my $args    = { %{ $options || {} } };
my @index   = split /\s+/, ( $args->{Index} // '' );
my %indexed = map { $_ => 1 } @index;
my @fields  = @ARGV ? @ARGV : sort keys %indexed;
for (@fields) { die "$_ is not in Index\n" unless $indexed{$_} }

my $redis = Web::Session::Redis->_getRedis($args);
printf "%s, %s %s, keys: %d\nfields: %s\n", $apply ? 'APPLY' : 'dry run',
  $storage, $module, $redis->dbsize, "@fields";

for my $f (@fields) {
    my @other = grep { index( $_, "${f}_" ) == 0 } @index;
    my ( $cursor, $sets, $members, $orphans, $nextReport ) =
      ( 0, 0, 0, 0, 100000 );
    my $t = time;
    do {
        my ( $next, $keys ) = $redis->scan(
            $cursor,
            MATCH => Web::Session::Redis::_globEscape($f) . '_*',
            COUNT => 1000
        );
        $cursor = $next;
        my @page = grep {
            my $k = $_;
            !grep { index( $k, "${_}_" ) == 0 } @other
        } @$keys;
        my $m = Web::Session::Redis::_smembers( $redis, \@page );
        my %ids;
        for my $set ( keys %$m ) {
            $m->{$set} =
              [ grep { $_ and Web::Session::Redis->isLlngKey( $args, $_ ) }
                  @{ $m->{$set} } ];
            $ids{$_} = 1 for @{ $m->{$set} };
        }
        my @ids = keys %ids;
        my %alive;
        @alive{@ids} = Web::Session::Redis::_mget( $redis, @ids );
        for my $set ( keys %$m ) {
            $sets++;
            for my $k ( @{ $m->{$set} } ) {
                $members++;
                next if defined $alive{$k};
                $orphans++;
                Web::Session::Redis->_removeOrphan( $redis, $set, $k )
                  if $apply;
            }
        }
        if ( $sets >= $nextReport ) {
            printf "  %-16s %d sets, %d members, %d orphans, %.0fs\n", $f,
              $sets, $members, $orphans, time - $t;
            $nextReport += 100000;
        }
        usleep( $sleep * 1000 ) if $sleep;
    } while ($cursor);
    printf "%-16s %d sets, %d members, %d orphans %s, %.0fs\n", $f, $sets,
      $members, $orphans, $apply ? 'removed' : 'found', time - $t;
}
printf "keys: %d\n", $redis->dbsize;
