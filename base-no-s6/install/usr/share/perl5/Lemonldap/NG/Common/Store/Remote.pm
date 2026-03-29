package Lemonldap::NG::Common::Store::Remote;

use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use File::Path     qw(make_path);
use File::Basename qw(dirname);
use Digest::SHA    qw(sha256_hex);

our $VERSION = '2.23.0';

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {
        timeout  => $args{timeout}  || 30,
        cacheDir => $args{cacheDir} || '/var/cache/lemonldap-ng/store',
    }, $class;

    $self->{ua} = LWP::UserAgent->new(
        agent   => "lemonldap-ng-store/$VERSION",
        timeout => $self->{timeout},
    );

    return $self;
}

# Fetch store index from URL
# Returns (success, data_or_error)
sub fetchIndex {
    my ( $self, $store_url ) = @_;

    # Normalize URL
    $store_url =~ s|/+$||;
    my $index_url = "$store_url/index.json";

    my $response = $self->{ua}->get($index_url);

    unless ( $response->is_success ) {
        return ( 0, "Failed to fetch $index_url: " . $response->status_line );
    }

    my $data;
    eval { $data = JSON->new->utf8->decode( $response->decoded_content ) };
    if ($@) {
        return ( 0, "Failed to parse index from $index_url: $@" );
    }

    return ( 1, $data );
}

# Fetch and cache store index
# Returns (success, data_or_error)
sub fetchIndexCached {
    my ( $self, $store_url, $force ) = @_;

    my $cache_file = $self->_cacheFile($store_url);

    # Use cache if fresh (< 1 hour) and not forced
    if (   !$force
        && -r $cache_file
        && ( time - ( stat($cache_file) )[9] ) < 3600 )
    {
        open my $fh, '<', $cache_file or return $self->fetchIndex($store_url);
        local $/;
        my $content = <$fh>;
        close $fh;

        my $data;
        eval { $data = JSON->new->utf8->decode($content) };
        return ( 1, $data ) unless $@;
    }

    my ( $ok, $data ) = $self->fetchIndex($store_url);
    if ($ok) {
        $self->_writeCache( $cache_file, $data );
    }
    return ( $ok, $data );
}

# Download a file to a local path
# Returns (success, error_message)
sub downloadFile {
    my ( $self, $url, $dest_path ) = @_;

    # Ensure destination directory exists
    my $dir = dirname($dest_path);
    unless ( -d $dir ) {
        make_path( $dir, { mode => 0755 } )
          or return ( 0, "Cannot create directory $dir: $!" );
    }

    my $response = $self->{ua}->get( $url, ':content_file' => $dest_path );

    unless ( $response->is_success ) {
        return ( 0, "Failed to download $url: " . $response->status_line );
    }

    return ( 1, undef );
}

# Download a file and verify SHA256
# Returns (success, error_message)
sub downloadAndVerify {
    my ( $self, $url, $dest_path, $expected_sha256 ) = @_;

    my ( $ok, $err ) = $self->downloadFile( $url, $dest_path );
    return ( $ok, $err ) unless $ok;

    # Verify SHA256
    open my $fh, '<', $dest_path
      or return ( 0, "Cannot read downloaded file: $!" );
    binmode $fh;
    my $sha = Digest::SHA->new(256);
    $sha->addfile($fh);
    close $fh;

    my $actual = $sha->hexdigest;
    if ( lc($actual) ne lc($expected_sha256) ) {
        unlink $dest_path;
        return ( 0,
                "SHA256 mismatch for $url:\n"
              . "  expected: $expected_sha256\n"
              . "  got:      $actual" );
    }

    return ( 1, undef );
}

# Fetch a signature file (.asc)
# Returns (success, path_or_error)
sub fetchSignature {
    my ( $self, $sig_url, $dest_path ) = @_;
    return $self->downloadFile( $sig_url, $dest_path );
}

sub _cacheFile {
    my ( $self, $store_url ) = @_;
    my $key = $store_url;
    $key =~ s|[^a-zA-Z0-9._-]|_|g;
    return "$self->{cacheDir}/$key.json";
}

sub _writeCache {
    my ( $self, $cache_file, $data ) = @_;
    my $dir = dirname($cache_file);
    unless ( -d $dir ) {
        eval { make_path( $dir, { mode => 0755 } ) };
        return if $@;    # silently skip if we can't create cache dir
    }

    if ( open my $fh, '>', $cache_file ) {
        print $fh JSON->new->utf8->encode($data);
        close $fh;
    }
}

1;
