# To enable it, add Twake::Wellknown into customPlugins key
#
package Twake::Wellknown;

use strict;
use Mouse;

extends 'Lemonldap::NG::Portal::Main::Plugin';

sub init {
    my $self = shift;
    $self->addAuthRoute(
        '.well-known' => { 'twake-configuration' => 'run' },
        ['GET']
    );
    $self->addUnauthRoute(
        '.well-known' => { 'twake-configuration' => 'run' },
        ['GET']
    );
    return 1;
}

sub run {
    my ( $self, $req ) = @_;
    return $self->sendJSONresponse(
        $req,
        {
            'twake-pass-login-uri' =>
              'https://oauthcallback.cozy.works/oidc/bitwarden/twake',
            'twake-flagship-login-uri' =>
              'https://manager-int.cozycloud.cc/linagora/twake',
        }
    );
}

1;
