package Apache::Session::Browseable::SQLite;

use strict;
use Web::Session::SQLite;

our $VERSION = '1.0.0';
our @ISA     = qw(Web::Session::SQLite);

# LemonLDAP::NG also calls populate() as a function
*populate = \&Web::Session::SQLite::populate;

1;
__END__

=head1 NAME

Apache::Session::Browseable::SQLite - Alias of L<Web::Session::SQLite>

=head1 DESCRIPTION

Installed by llng-docker in place of the module of Apache::Session::Browseable,
so that a configuration still naming C<Apache::Session::Browseable::SQLite> uses
L<Web::Session::SQLite>, which stores the sessions in the same format. See
"Session backends: Web::Session" in the README of the base image.

=cut
