#!/usr/bin/perl
# Usage: redis-clean-orphans.pl [--apply] [--storage globalStorage] [field...]
#
# Removes from the Redis index sets of the storage (default globalStorage)
# the members whose session
# no longer exists, for the given fields (default: every field of Index). It
# runs Web::Session::Redis->searchOnExpr( field, '*' ), whose lazy cleanup
# removes each orphan with an atomic EXISTS + SREM: a set losing its last
# member disappears. Sessions are only read. Without --apply, only prints the
# plan. Needs Web::Session. Prints no secret.
use strict;
use warnings;
use JSON;
use Time::HiRes qw(time);
use Web::Session::Redis;

use Getopt::Long;
my ( $apply, $storage ) = ( 0, 'globalStorage' );
GetOptions( 'apply' => \$apply, 'storage=s' => \$storage )
  or die "Usage: $0 [--apply] [--storage globalStorage] [field...]\n";

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
my %indexed = map { $_ => 1 } split /\s+/, ( $args->{Index} // '' );
my @fields  = @ARGV ? @ARGV : sort keys %indexed;
for (@fields) {
    die "$_ is not in Index: searchOnExpr would read every session\n"
      unless $indexed{$_};
}

my $redis = Web::Session::Redis->_getRedis($args);
printf "%s, %s %s, keys: %d\nfields: %s\n", $apply ? 'APPLY' : 'dry run',
  $storage, $module, $redis->dbsize, "@fields";
exit 0 unless $apply;
for my $f (@fields) {
    my ( $t, $before ) = ( time, $redis->dbsize );
    my $r = Web::Session::Redis->searchOnExpr( $args, $f, '*', '_session_id' );
    my $after = $redis->dbsize;
    printf "%-16s %7d sessions indexed, keys %d -> %d (%+d), %.0fs\n", $f,
      scalar( keys %$r ), $before, $after, $after - $before, time - $t;
}
printf "keys: %d\n", $redis->dbsize;
