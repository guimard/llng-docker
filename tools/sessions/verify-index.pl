#!/usr/bin/perl
# Usage: verify-index.pl [--storage globalStorage] field...
#
# Read only. For each field, compares the sessions returned by searchOn() for
# every value with those of a full read of the storage, through the session
# backend of the LemonLDAP::NG configuration: an index missing entries
# ("missing") or holding stale ones ("unexpected") shows up here. Sessions
# created or deleted while it runs may appear in either column. One searchOn()
# per distinct value: long on a large storage. Prints counts only.
use strict;
use warnings;
use Getopt::Long;
use JSON;
use Lemonldap::NG::Common::Apache::Session;

my $storage = 'globalStorage';
GetOptions( 'storage=s' => \$storage ) and @ARGV
  or die "Usage: $0 [--storage globalStorage] field...\n";

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
my $module = $conf->{$storage} || $conf->{globalStorage}
  or die "$storage is not set\n";
my $options = $conf->{$storage} ? $conf->{"${storage}Options"} : $conf->{globalStorageOptions};
my $args = { %{ $options || {} }, backend => $module };
my $s    = 'Lemonldap::NG::Common::Apache::Session';

my $all = $s->get_key_from_all_sessions( $args, sub { $_[0] } ) || {};
printf "%s (%s): %d sessions\n", $storage, $module, scalar keys %$all;
for my $f (@ARGV) {
    my %byVal;
    for my $id ( keys %$all ) {
        my $v = $all->{$id}->{$f};
        push @{ $byVal{$v} }, $id if ( defined $v and !ref $v and length $v );
    }
    my ( $ok, $missing, $extra ) = ( 0, 0, 0 );
    for my $v ( keys %byVal ) {
        my $r   = $s->searchOn( $args, $f, $v ) || {};
        my %exp = map { $_ => 1 } @{ $byVal{$v} };
        $ok      += grep { $r->{$_} } keys %exp;
        $missing += grep { !$r->{$_} } keys %exp;
        $extra   += grep { !$exp{$_} } keys %$r;
    }
    printf "%-16s %6d values, %7d sessions found, %d missing, %d unexpected\n",
      $f, scalar keys %byVal, $ok, $missing, $extra;
}
