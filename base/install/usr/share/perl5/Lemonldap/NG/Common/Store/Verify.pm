package Lemonldap::NG::Common::Store::Verify;

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);

our $VERSION = '2.23.0';

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {
        gpgVerify       => $args{gpgVerify} || 'optional',
        gpgKeyring      => $args{gpgKeyring},
        gpgFingerprints => $args{gpgFingerprints} || [],
    }, $class;
    return $self;
}

# Verify SHA256 checksum of a file
# Returns (success, error_message)
sub verifySha256 {
    my ( $self, $file, $expected ) = @_;

    open my $fh, '<', $file
      or return ( 0, "Cannot read file $file: $!" );
    binmode $fh;
    my $sha = Digest::SHA->new(256);
    $sha->addfile($fh);
    close $fh;

    my $actual = $sha->hexdigest;
    if ( lc($actual) ne lc($expected) ) {
        return ( 0,
                "SHA256 mismatch:\n"
              . "  expected: $expected\n"
              . "  got:      $actual" );
    }

    return ( 1, undef );
}

# Verify GPG detached signature
# Returns (success, message)
# Behavior depends on gpgVerify mode: required, optional, disabled
sub verifyGpg {
    my ( $self, $archive_file, $sig_file ) = @_;

    # If GPG verification is disabled, skip
    if ( $self->{gpgVerify} eq 'disabled' ) {
        return ( 1, 'GPG verification disabled' );
    }

    # Check if signature file exists
    unless ( $sig_file && -r $sig_file ) {
        if ( $self->{gpgVerify} eq 'required' ) {
            return ( 0, 'GPG signature required but not available' );
        }
        return ( 1, 'No GPG signature available (gpgVerify=optional)' );
    }

    # Check if gpg is available
    my $gpg = _findGpg();
    unless ($gpg) {
        if ( $self->{gpgVerify} eq 'required' ) {
            return ( 0,
                'gpg not found but GPG verification is required. Install gnupg.'
            );
        }
        return ( 1,
            'gpg not found, skipping GPG verification (gpgVerify=optional)' );
    }

    # Build gpg --verify command
    my @cmd = ( $gpg, '--batch', '--verify' );

    if ( $self->{gpgKeyring} && -r $self->{gpgKeyring} ) {
        push @cmd, '--keyring', $self->{gpgKeyring};
    }

    push @cmd, $sig_file, $archive_file;

    # Execute gpg --verify
    my $output = `@cmd 2>&1`;
    my $exit   = $? >> 8;

    if ( $exit != 0 ) {
        if ( $self->{gpgVerify} eq 'required' ) {
            return ( 0, "GPG verification failed:\n$output" );
        }
        return ( 1, "GPG verification failed (gpgVerify=optional):\n$output" );
    }

    # If fingerprints are configured, verify the signing key matches
    if ( @{ $self->{gpgFingerprints} } ) {
        my $fingerprint_ok = 0;
        for my $fp ( @{ $self->{gpgFingerprints} } ) {
            if ( $output =~ /\Q$fp\E/i ) {
                $fingerprint_ok = 1;
                last;
            }
        }
        unless ($fingerprint_ok) {
            if ( $self->{gpgVerify} eq 'required' ) {
                return ( 0,
"GPG signature valid but signing key not in trusted fingerprints"
                );
            }
            return ( 1,
"Warning: GPG signature valid but signing key not in trusted fingerprints"
            );
        }
    }

    return ( 1, 'GPG signature verified' );
}

# Check HTTPS transport security
# Returns (secure, warning_message)
sub checkTransport {
    my ( $self, $url ) = @_;
    if ( $url =~ m|^https://|i ) {
        return ( 1, undef );
    }
    if ( $url =~ m|^http://|i ) {
        return ( 0, "WARNING: Store URL uses HTTP (not HTTPS): $url" );
    }
    return ( 0, "Unknown protocol in URL: $url" );
}

sub _findGpg {
    for my $path ( '/usr/bin/gpg', '/usr/local/bin/gpg' ) {
        return $path if -x $path;
    }

    # Try PATH
    my $which = `which gpg 2>/dev/null`;
    chomp $which;
    return $which if $which && -x $which;
    return undef;
}

1;
