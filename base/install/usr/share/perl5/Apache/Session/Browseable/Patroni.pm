package Apache::Session::Browseable::Patroni;

use strict;
use Web::Session::Patroni;

our $VERSION = '1.0.0';
our @ISA     = qw(Web::Session::Patroni);

# LemonLDAP::NG also calls populate() as a function
*populate = \&Web::Session::Patroni::populate;

1;
__END__

=head1 NAME

Apache::Session::Browseable::Patroni - Alias of L<Web::Session::Patroni>

=head1 DESCRIPTION

Installed by llng-docker in place of the module of Apache::Session::Browseable,
so that a configuration still naming C<Apache::Session::Browseable::Patroni> uses
L<Web::Session::Patroni>, which stores the sessions in the same format. See
"Session backends: Web::Session" in the README of the base image.

=cut
