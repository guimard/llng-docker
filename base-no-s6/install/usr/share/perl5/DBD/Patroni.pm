#  -*-cperl-*-
#
#  DBD::Patroni - DBI driver for PostgreSQL with Patroni cluster support
#
#  Copyright (c) 2025 Xavier Guimard
#
#  You may distribute under the terms of either the GNU General Public
#  License or the Artistic License, as specified in the Perl README file.

use strict;
use warnings;

package DBD::Patroni;

use DBI;
require DBD::Pg;

our $VERSION = '0.03';
our $drh     = undef;    # Driver handle
our $err     = 0;        # DBI error code
our $errstr  = '';       # DBI error string
our $state   = '';       # DBI state
our $rr_idx  = 0;        # Round-robin index for replica selection

# Driver-level cluster discovery cache (opt-in via patroni_shared_cache).
# Keyed by normalized patroni_url string. Each entry:
#   { leader => \%member, replicas => \@members, expires_at => epoch }
our %_cluster_cache;

# Load submodules
require DBD::Patroni::dr;
require DBD::Patroni::db;
require DBD::Patroni::st;

# DBI driver method - required for DBI->connect("dbi:Patroni:...")
sub driver {
    return $drh if $drh;
    my ( $class, $attr ) = @_;

    $class .= "::dr";

    $drh = DBI::_new_drh(
        $class,
        {
            Name        => 'Patroni',
            Version     => $VERSION,
            Attribution => 'DBD::Patroni by Xavier Guimard',
        }
    );
    return $drh;
}

# Discover Patroni cluster via REST API
sub _discover_cluster {
    my ( $urls, $timeout, $ssl_opts ) = @_;
    $timeout  //= 3;
    $ssl_opts //= {};

    require LWP::UserAgent;
    require JSON;

    my %ua_opts = (
        timeout   => $timeout,
        env_proxy => 1,
    );

    # Configure SSL options for Patroni API calls
    if ( defined $ssl_opts->{verify} ) {
        if ( $ssl_opts->{verify} ) {
            # Enable full SSL verification (hostname + certificate chain)
            $ua_opts{ssl_opts} = {
                verify_hostname => 1,
                SSL_verify_mode => 1,    # IO::Socket::SSL::SSL_VERIFY_PEER
            };
        }
        else {
            # Disable SSL verification (no hostname check, no cert verification)
            $ua_opts{ssl_opts} = {
                verify_hostname => 0,
                SSL_verify_mode => 0,    # IO::Socket::SSL::SSL_VERIFY_NONE
            };
        }
    }

    # Add CA file if specified
    if ( $ssl_opts->{ca_file} ) {
        $ua_opts{ssl_opts}{SSL_ca_file} = $ssl_opts->{ca_file};
    }

    # Add client certificate and key for mTLS (must be provided together)
    if ( $ssl_opts->{cert_file} || $ssl_opts->{key_file} ) {
        if ( !$ssl_opts->{cert_file} || !$ssl_opts->{key_file} ) {
            die "patroni_ssl_cert_file and patroni_ssl_key_file must be provided together\n";
        }
        $ua_opts{ssl_opts}{SSL_cert_file} = $ssl_opts->{cert_file};
        $ua_opts{ssl_opts}{SSL_key_file}  = $ssl_opts->{key_file};
    }

    my $ua = LWP::UserAgent->new(%ua_opts);

    for my $url ( split /[,\s]+/, $urls ) {
        next unless $url;
        my $resp = $ua->get($url);
        next unless $resp->is_success;

        my $data = eval { JSON::decode_json( $resp->decoded_content ) };
        next if $@ or !$data->{members} or ref( $data->{members} ) ne 'ARRAY';

        my ($leader) = grep { $_->{role} eq 'leader' } @{ $data->{members} };
        my @replicas = grep { $_->{role} ne 'leader' } @{ $data->{members} };

        return ( $leader, @replicas ) if $leader;
    }
    return;
}

# Select a replica based on load balancing mode
sub _select_replica {
    my ( $replicas, $mode ) = @_;
    return undef unless $replicas && @$replicas;

    $mode //= 'round_robin';

    if ( $mode eq 'random' ) {
        return $replicas->[ int( rand(@$replicas) ) ];
    }
    elsif ( $mode eq 'leader_only' ) {
        return undef;
    }
    else {    # round_robin
        return $replicas->[ $rr_idx++ % @$replicas ];
    }
}

# Parse and extract Patroni parameters from DSN
sub _parse_dsn {
    my ($dsn) = @_;
    my %params;
    my @remaining;

    for my $part ( split /;/, $dsn ) {
        if ( $part =~ /^(patroni_(?:url|lb|timeout|ssl_verify|ssl_ca_file|ssl_cert_file|ssl_key_file|shared_cache|cache_ttl))=(.*)$/i ) {
            $params{ lc($1) } = $2;
        }
        else {
            push @remaining, $part;
        }
    }

    return ( join( ';', @remaining ), \%params );
}

# Build a normalized cache key from a patroni_url string (order-insensitive).
sub _cache_key {
    my ($urls) = @_;
    return '' unless defined $urls;
    return join( ',', sort grep { length } split /[,\s]+/, $urls );
}

# Discover cluster, optionally using the driver-level cache.
# Returns (leader, @replicas) just like _discover_cluster.
sub _discover_cluster_cached {
    my ( $urls, $timeout, $ssl_opts, $use_cache, $ttl ) = @_;

    if ($use_cache) {
        my $key   = _cache_key($urls);
        my $entry = $_cluster_cache{$key};
        if ( $entry && $entry->{expires_at} > time ) {
            return ( $entry->{leader}, @{ $entry->{replicas} } );
        }

        my ( $leader, @replicas ) =
          _discover_cluster( $urls, $timeout, $ssl_opts );
        if ($leader) {
            $_cluster_cache{$key} = {
                leader     => $leader,
                replicas   => [@replicas],
                expires_at => time + ( $ttl // 30 ),
            };
        }
        return ( $leader, @replicas );
    }

    return _discover_cluster( $urls, $timeout, $ssl_opts );
}

# Drop a cached cluster entry (used after a connection failure).
sub _invalidate_cluster_cache {
    my ($urls) = @_;
    delete $_cluster_cache{ _cache_key($urls) };
    return;
}

# Extract user-supplied host/port from a DSN, before _build_dsn rewrites it.
# Returns ($host, $port) — either or both may be undef.
sub _extract_host_port {
    my ($dsn) = @_;
    return ( undef, undef ) unless defined $dsn;
    my ($host) = $dsn =~ /(?:^|;)\s*host=([^;]+)/i;
    my ($port) = $dsn =~ /(?:^|;)\s*port=([^;]+)/i;
    return ( $host, $port );
}

# Build DSN with host/port, cleaning up any existing host/port params
sub _build_dsn {
    my ( $dsn, $host, $port ) = @_;

    # Remove existing host/port parameters
    $dsn =~ s/(?:host|port)=[^;]*;?//gi;

    # Clean up multiple semicolons and leading/trailing semicolons
    $dsn =~ s/;+/;/g;
    $dsn =~ s/^;|;$//g;

    # Append new host/port
    return "$dsn;host=$host;port=$port";
}

# Fallback connection used when Patroni cluster discovery fails.
# Connects directly to the DSN-supplied host, detects its role via
# pg_is_in_recovery(), and returns ($dbh, $role) — or () on failure.
# Emits a warn() so the application notices the degraded state.
sub _connect_fallback {
    my ( $dsn, $host, $port, $user, $pass, $attr, $patroni_url ) = @_;
    return unless $host;

    my $fb_dsn = _build_dsn( $dsn, $host, $port // 5432 );
    my $dbh    = DBI->connect( "dbi:Pg:$fb_dsn", $user, $pass,
        { %{ $attr || {} }, RaiseError => 0, PrintError => 0 } );
    return unless $dbh;

    my $role = 'unknown';
    eval {
        my ($in_recovery) =
          $dbh->selectrow_array('SELECT pg_is_in_recovery()');
        $role =
          defined($in_recovery) && $in_recovery ? 'replica' : 'leader';
    };

    warn sprintf(
        "DBD::Patroni: cluster discovery failed for %s, falling back to DSN host %s as %s (degraded mode)\n",
        $patroni_url // '?',
        $host, $role
    );
    return ( $dbh, $role );
}

# Detect read-only queries
sub _is_readonly {
    my $sql = shift;
    return 0 unless defined $sql;

    # SELECT or WITH ... SELECT (CTE)
    return $sql =~ /^\s*(SELECT|WITH\s+\w+.*?\bSELECT)\b/si ? 1 : 0;
}

# Detect connection errors
sub _is_connection_error {
    my $error = shift;
    return 0 unless $error;

    return 1
      if $error =~
/(?:c(?:o(?:nnection (?:re(?:fused|set)|timed out)|uld not connect)|annot execute .* in a read-only transaction)|t(?:he database system is (?:s(?:hutting down|tarting up)|in recovery mode)|erminating connection)|no(?: connection to the server|t accepting connections)|re(?:covery is in progress|ad-only transaction)|(?:server closed the|lost) connection|hot standby mode is disabled)/i;

    return 0;
}

# Execute with automatic retry on failure (shared helper)
sub _with_retry {
    my ( $dbh, $target, $code ) = @_;
    my $result;
    my $wantarray = wantarray;

    foreach my $attempt ( 0 .. 1 ) {
        my @results;
        eval {
            if ($wantarray) {
                @results = $code->();
            }
            else {
                $result = $code->();
            }
        };

        if ($@) {
            my $error = $@;

            # Only retry on connection errors, not SQL errors
            if ( _is_connection_error($error) && $attempt == 0 ) {
                warn
"DBD::Patroni: Connection error on $target, rediscovering cluster...\n";
                if ( DBD::Patroni::db::_rediscover_cluster($dbh) ) {
                    next;
                }
            }
            die $error;
        }
        return $wantarray ? @results : $result;
    }
}

1;

__END__

=head1 NAME

DBD::Patroni - DBI driver for PostgreSQL with Patroni cluster support

=head1 SYNOPSIS

    use DBI;

    # Standard DBI connection with patroni_url in DSN
    my $dbh = DBI->connect(
        "dbi:Patroni:dbname=mydb;patroni_url=http://patroni1:8008/cluster,http://patroni2:8008/cluster",
        $user, $password
    );

    # Or with attributes
    my $dbh = DBI->connect(
        "dbi:Patroni:dbname=mydb",
        $user, $password,
        {
            patroni_url => "http://patroni1:8008/cluster",
            patroni_lb  => "round_robin",
        }
    );

    # With HTTPS and disabled SSL verification (self-signed certs)
    my $dbh = DBI->connect(
        "dbi:Patroni:dbname=mydb;patroni_url=https://patroni1:8008/cluster;patroni_ssl_verify=0",
        $user, $password
    );

    # SELECT queries go to replica
    my $sth = $dbh->prepare("SELECT * FROM users WHERE id = ?");
    $sth->execute(1);

    # INSERT/UPDATE/DELETE queries go to leader
    $dbh->do("INSERT INTO users (name) VALUES (?)", undef, "John");

    $dbh->disconnect;

=head1 DESCRIPTION

DBD::Patroni is a DBI driver that wraps DBD::Pg and provides automatic
routing of queries to the appropriate node in a Patroni-managed PostgreSQL
cluster.

=head2 Features

=over 4

=item * Standard DBI interface - use DBI->connect("dbi:Patroni:...")

=item * Automatic leader discovery via Patroni REST API

=item * Read queries (SELECT) routed to replicas

=item * Write queries (INSERT, UPDATE, DELETE) routed to leader

=item * Configurable load balancing for replicas

=item * Automatic failover with retry on connection errors

=back

=head1 CONNECTION

    my $dbh = DBI->connect($dsn, $user, $pass, \%attr);

The DSN format is:

    dbi:Patroni:dbname=...;patroni_url=...;[other_pg_options]

All standard L<DBD::Pg> connection parameters are supported.

Patroni-specific parameters can be in the DSN or attributes hash.
Attributes hash takes precedence.

=head1 CONNECTION ATTRIBUTES

=over 4

=item patroni_url (required)

Comma-separated list of Patroni REST API endpoints.

=item patroni_lb

Load balancing mode: C<round_robin> (default), C<random>, or C<leader_only>.

=item patroni_timeout

HTTP timeout in seconds for Patroni API calls. Default: 3

=item patroni_ssl_verify

Enable or disable SSL certificate verification for Patroni API calls.
Accepts: C<0>, C<1>, C<no>, C<yes>, C<off>, C<on>, C<false>, C<true>.

Set to C<0> or C<no> to disable SSL verification (hostname check and
certificate validation). This is useful for self-signed certificates
or testing environments.

B<Note:> These SSL options only affect connections to the Patroni REST API,
not the PostgreSQL database connections (use DBD::Pg sslmode for that).

=item patroni_ssl_ca_file

Path to a CA certificate file for Patroni API SSL verification.

=item patroni_ssl_cert_file

Path to a client certificate file for Patroni API mutual TLS authentication.
Must be used together with C<patroni_ssl_key_file>.

=item patroni_ssl_key_file

Path to a client private key file for Patroni API mutual TLS authentication.
Must be used together with C<patroni_ssl_cert_file>.

=item patroni_shared_cache

Enable a process-wide cluster discovery cache shared by every DBD::Patroni
handle that uses the same C<patroni_url>. Disabled by default (C<0>).
Accepts: C<0>, C<1>, C<no>, C<yes>, C<off>, C<on>, C<false>, C<true>.

When enabled, the first connection performs the HTTP discovery and stores
the topology (leader + replicas) in C<%DBD::Patroni::_cluster_cache>.
Subsequent connections to the same URL reuse the cached topology until
C<patroni_cache_ttl> elapses, avoiding redundant calls to the Patroni REST
API.

The cache is also automatically invalidated whenever a connection error
triggers a rediscovery — so a failover on one handle effectively refreshes
the topology for every later handle. Handles that already hold live
connections continue to use them until they themselves hit an error.

=item patroni_cache_ttl

Time-to-live (seconds) for entries in the shared cluster cache. Default: 30.
Only used when C<patroni_shared_cache> is enabled.

=back

=head1 QUERY ROUTING

=over 4

=item * B<SELECT> and B<WITH...SELECT> go to replica

=item * All other queries go to leader

=back

=head1 FAILOVER

On connection failure, DBD::Patroni will:

=over 4

=item 1. Query Patroni API to discover current leader

=item 2. Reconnect to new leader/replica

=item 3. Retry the failed operation

=back

=head1 FALLBACK HOST (DEGRADED MODE)

If the DSN contains a C<host=> (and optionally C<port=>) parameter, it is
used as an implicit fallback when the Patroni REST API cannot be reached
(network partition, Patroni restart, etc.). In that case:

=over 4

=item * The driver connects directly to the DSN-supplied host.

=item * C<SELECT pg_is_in_recovery()> is issued to detect whether that
host is the leader or a replica; a C<warn()> is emitted.

=item * That single connection is used for both reads and writes
(degraded mode — no replica load balancing).

=item * The next connection error triggers a rediscovery; if Patroni is
reachable again, normal leader/replica routing is restored automatically.

=back

There is no opt-in flag: a C<host=> in the DSN previously had no effect
(it was overwritten during cluster discovery), so this behavior is
strictly additive.

=head1 SEE ALSO

L<DBD::Pg>, L<DBI>

=head1 AUTHOR

Xavier Guimard

=head1 LICENSE

Same as Perl itself.

=cut
