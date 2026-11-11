#!/usr/bin/perl

use Data::Dumper;
use Plack::Builder;

# Build manager app
use Lemonldap::NG::Manager;

# AUTHBASIC=<login>:<password> protects the manager when PROTECTION=none.
# Parse it once and refuse to start with a malformed value.
my ( $auth_user, $auth_pass );
if ( my $basic = $ENV{AUTHBASIC} ) {
    ( $auth_user, $auth_pass ) = $basic =~ /^([^:]*):(.*)$/;
    die "Malformed AUTHBASIC\n"
      unless defined $auth_user
      and length $auth_user
      and length $auth_pass;
}

# Constant-time comparison: avoid leaking the password length or content.
sub _ct_eq {
    my ( $a, $b ) = @_;
    return 0 unless length $a == length $b;
    my $diff = 0;
    $diff |= ord( substr( $a, $_, 1 ) ) ^ ord( substr( $b, $_, 1 ) )
      for 0 .. length($a) - 1;
    return $diff == 0;
}

sub authen_cb {
    my ( $user, $pass ) = @_;
    return 0 unless length $user and length $pass;
    return _ct_eq( $user, $auth_user ) && _ct_eq( $pass, $auth_pass );
}

my $manager = builder {
    enable "Plack::Middleware::Static",
      path => '^/static/',
      root => '/usr/share/lemonldap-ng/manager/htdocs/';
    enable "Plack::Middleware::Static",
      path => sub { s!^/doc/!! },
      root => '/usr/share/doc/lemonldap-ng/';
    enable "Plack::Middleware::Static",
      path => '^/lib/',
      root => '/usr/share/doc/lemonldap-ng/pages/documentation/current/';
    enable "Plack::Middleware::Static",
      path => '^/javascript/',
      root => '/usr/share/';
    if ($ENV{AUTHBASIC}) {
        print "Enable AuthBasic auth";
        enable "Auth::Basic", authenticator => \&authen_cb;
    }
    Lemonldap::NG::Manager->run( {} );
};

my $domain = $ENV{SSODOMAIN} || "example.com";

# Global app
if ( $ENV{SSODOMAIN} ) {
    print STDERR <<EOF;
LemonLDAP demo server:
* http://manager.$ENV{SSODOMAIN}/

EOF
}
builder {
    mount "http://manager.$domain/" => $manager;
};
