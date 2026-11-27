package Apache::Session::Browseable::Redis;

use strict;
use Web::Session::Redis;

our $VERSION = '1.0.0';
our @ISA     = qw(Web::Session::Redis);

# LemonLDAP::NG also calls populate() as a function
*populate = \&Web::Session::Redis::populate;

1;
__END__

=head1 NAME

Apache::Session::Browseable::Redis - Alias of L<Web::Session::Redis>

=head1 DESCRIPTION

Installed by llng-docker in place of the module of Apache::Session::Browseable,
so that a configuration still naming C<Apache::Session::Browseable::Redis> uses
L<Web::Session::Redis>, which stores the sessions in the same format. See
"Session backends: Web::Session" in the README of the base image.

=cut
