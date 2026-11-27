package Apache::Session::Browseable::Cassandra;

use strict;
use Web::Session::Cassandra;

our $VERSION = '1.0.0';
our @ISA     = qw(Web::Session::Cassandra);

# LemonLDAP::NG also calls populate() as a function
*populate = \&Web::Session::Cassandra::populate;

1;
__END__

=head1 NAME

Apache::Session::Browseable::Cassandra - Alias of L<Web::Session::Cassandra>

=head1 DESCRIPTION

Installed by llng-docker in place of the module of Apache::Session::Browseable,
so that a configuration still naming C<Apache::Session::Browseable::Cassandra> uses
L<Web::Session::Cassandra>, which stores the sessions in the same format. See
"Session backends: Web::Session" in the README of the base image.

=cut
