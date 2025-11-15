# To enable it, add Twake::Wellknown into customPlugins key
#
package Twake::Wellknown;

use strict;
use Mouse;

extends 'Lemonldap::NG::Portal::Main::Plugin';

sub init {
    my $self = shift;
    if (    $self->conf->{twakeWellKnown}
        and ref $self->conf->{twakeWellKnown}
        and %{ $self->conf->{twakeWellKnown} } )
    {
        $self->addAuthRoute(
            '.well-known' => { 'twake-configuration' => 'run' },
            ['GET']
        );
        $self->addUnauthRoute(
            '.well-known' => { 'twake-configuration' => 'run' },
            ['GET']
        );
    }
    else {
        $self->logger->warn("No values inside twakeWellKnown, aborting");
    }
    return 1;
}

sub run {
    my ( $self, $req ) = @_;
    return $self->sendJSONresponse( $req, $self->conf->{twakeWellKnown} );
}

1;
