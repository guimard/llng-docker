package Apache::Session::Browseable::File;

use strict;
use Web::Session::File;

our $VERSION = '1.0.0';
our @ISA     = qw(Web::Session::File);

# LemonLDAP::NG also calls populate() as a function
*populate = \&Web::Session::File::populate;

1;
__END__

=head1 NAME

Apache::Session::Browseable::File - Alias of L<Web::Session::File>

=head1 DESCRIPTION

Installed by llng-docker in place of the module of Apache::Session::Browseable,
so that a configuration still naming C<Apache::Session::Browseable::File> uses
L<Web::Session::File>, which stores the sessions in the same format. See
"Session backends: Web::Session" in the README of the base image.

=cut
