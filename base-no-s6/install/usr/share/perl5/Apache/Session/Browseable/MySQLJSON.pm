package Apache::Session::Browseable::MySQLJSON;

use strict;
use Web::Session::MySQLJSON;

our $VERSION = '1.0.0';
our @ISA     = qw(Web::Session::MySQLJSON);

# LemonLDAP::NG also calls populate() as a function
*populate = \&Web::Session::MySQLJSON::populate;

1;
__END__

=head1 NAME

Apache::Session::Browseable::MySQLJSON - Alias of L<Web::Session::MySQLJSON>

=head1 DESCRIPTION

Installed by llng-docker in place of the module of Apache::Session::Browseable,
so that a configuration still naming C<Apache::Session::Browseable::MySQLJSON> uses
L<Web::Session::MySQLJSON>, which stores the sessions in the same format. See
"Session backends: Web::Session" in the README of the base image.

=cut
