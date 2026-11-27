package Apache::Session::Browseable::LDAP;

use strict;
use Web::Session::LDAP;

our $VERSION = '1.0.0';
our @ISA     = qw(Web::Session::LDAP);

# LemonLDAP::NG also calls populate() as a function
*populate = \&Web::Session::LDAP::populate;

1;
__END__

=head1 NAME

Apache::Session::Browseable::LDAP - Alias of L<Web::Session::LDAP>

=head1 DESCRIPTION

Installed by llng-docker in place of the module of Apache::Session::Browseable,
so that a configuration still naming C<Apache::Session::Browseable::LDAP> uses
L<Web::Session::LDAP>, which stores the sessions in the same format. See
"Session backends: Web::Session" in the README of the base image.

=cut
