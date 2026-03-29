package Lemonldap::NG::Common::Store::State;

use strict;
use warnings;
use JSON;
use File::Path     qw(make_path);
use File::Basename qw(dirname);

our $VERSION = '2.23.0';

sub new {
    my ( $class, %args ) = @_;
    my $self = bless { stateFile => $args{stateFile}
          || '/var/lib/lemonldap-ng/plugins-state.json', }, $class;
    $self->_load();
    return $self;
}

sub _load {
    my ($self) = @_;
    my $file = $self->{stateFile};

    if ( -r $file ) {
        open my $fh, '<', $file or do {
            warn "Cannot read state file $file: $!\n";
            $self->{state} = { installed => {} };
            return;
        };
        local $/;
        my $content = <$fh>;
        close $fh;

        eval { $self->{state} = JSON->new->utf8->decode($content) };
        if ($@) {
            warn "Cannot parse state file $file: $@\n";
            $self->{state} = { installed => {}, stores => {} };
        }
    }
    else {
        $self->{state} = { installed => {}, stores => {} };
    }
    $self->{state}{stores} ||= {};
}

sub _save {
    my ($self) = @_;
    my $file = $self->{stateFile};

    # Create parent directory if needed
    my $dir = dirname($file);
    unless ( -d $dir ) {
        make_path( $dir, { mode => 0755 } )
          or die "Cannot create directory $dir: $!\n";
    }

    my $json    = JSON->new->utf8->pretty->canonical;
    my $content = $json->encode( $self->{state} );

    open my $fh, '>', $file
      or die "Cannot write state file $file: $!\n";
    print $fh $content;
    close $fh;

    chmod 0644, $file;
}

# Get info about an installed plugin
sub get {
    my ( $self, $name ) = @_;
    return $self->{state}{installed}{$name};
}

# Record a plugin installation
sub add {
    my ( $self, $name, %info ) = @_;
    $self->{state}{installed}{$name} = {
        version        => $info{version},
        installed_from => $info{installed_from},
        installed_date => _now(),
        archive_sha256 => $info{archive_sha256},
        files          => $info{files} || [],
    };
    $self->_save();
}

# Remove a plugin record
sub remove {
    my ( $self, $name ) = @_;
    delete $self->{state}{installed}{$name};
    $self->_save();
}

# List all installed plugins
sub installed {
    my ($self) = @_;
    return %{ $self->{state}{installed} || {} };
}

# Check if a plugin is installed
sub isInstalled {
    my ( $self, $name ) = @_;
    return exists $self->{state}{installed}{$name};
}

# Store management

# Get store info (fingerprint, etc.)
sub getStore {
    my ( $self, $url ) = @_;
    return $self->{state}{stores}{$url};
}

# Record a store with its GPG fingerprint
sub addStore {
    my ( $self, $url, %info ) = @_;
    $self->{state}{stores}{$url} = {
        gpgFingerprint => $info{gpgFingerprint},
        added_date     => _now(),
    };
    $self->_save();
}

# Remove a store record
sub removeStore {
    my ( $self, $url ) = @_;
    delete $self->{state}{stores}{$url};
    $self->_save();
}

# Check if a store's GPG fingerprint has changed
# Returns (ok, message)
sub checkStoreFingerprint {
    my ( $self, $url, $fingerprint ) = @_;
    my $store = $self->{state}{stores}{$url};
    return ( 1, undef ) unless $store && $store->{gpgFingerprint};
    if ( lc( $store->{gpgFingerprint} ) ne lc($fingerprint) ) {
        return ( 0,
                "GPG fingerprint mismatch for store $url!\n"
              . "  Expected: $store->{gpgFingerprint}\n"
              . "  Got:      $fingerprint\n"
              . "  Use 'remove-store' + 'add-store' to accept the new key." );
    }
    return ( 1, undef );
}

sub _now {
    my @t = gmtime();
    return sprintf(
        '%04d-%02d-%02dT%02d:%02d:%02dZ',
        $t[5] + 1900,
        $t[4] + 1,
        $t[3], $t[2], $t[1], $t[0]
    );
}

1;
