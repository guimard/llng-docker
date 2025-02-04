#!/usr/bin/perl

use Data::Dumper;
use Plack::Builder;

# Build manager app
use Lemonldap::NG::Manager;

sub authen_cb {
    return $_[0] eq $ENV{AUTHUSER} && $_[1] eq $ENV{AUTHPWD};
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
