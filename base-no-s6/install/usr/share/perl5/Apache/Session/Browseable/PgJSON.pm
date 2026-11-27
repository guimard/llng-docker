package Apache::Session::Browseable::PgJSON;

use strict;
use Web::Session::PgJSON;

our $VERSION = '1.0.0';
our @ISA     = qw(Web::Session::PgJSON);

# LemonLDAP::NG also calls populate() as a function
*populate = \&Web::Session::PgJSON::populate;

1;
__END__

=head1 NAME

Apache::Session::Browseable::PgJSON - Alias of L<Web::Session::PgJSON>

=head1 DESCRIPTION

Installed by llng-docker in place of the module of Apache::Session::Browseable,
so that a configuration still naming C<Apache::Session::Browseable::PgJSON> uses
L<Web::Session::PgJSON>, which stores the sessions in the same format. See
"Session backends: Web::Session" in the README of the base image.

=cut
