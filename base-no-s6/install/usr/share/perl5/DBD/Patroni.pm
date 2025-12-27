#  -*-cperl-*-
#
#  DBD::Patroni - DBI driver for PostgreSQL with Patroni cluster support
#
#  Copyright (c) 2024 Xavier Guimard
#
#  You may distribute under the terms of either the GNU General Public
#  License or the Artistic License, as specified in the Perl README file.

package DBD::Patroni;

use strict;
use warnings;
use 5.010001;

our $VERSION = '0.01';

use DBI;
require DBD::Pg;

# Discover Patroni cluster via REST API
sub _discover_cluster {
    my ( $urls, $timeout ) = @_;
    $timeout //= 3;

    require LWP::UserAgent;
    require JSON;

    my $ua = LWP::UserAgent->new(
        timeout   => $timeout,
        env_proxy => 1,
    );

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
    die "DBD::Patroni: Cannot discover cluster from: $urls\n";
}

# Select a replica based on load balancing mode
our $rr_idx = 0;

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
        if ( $part =~ /^(patroni_url|patroni_lb|patroni_timeout)=(.*)$/i ) {
            $params{ lc($1) } = $2;
        }
        else {
            push @remaining, $part;
        }
    }

    return ( join( ';', @remaining ), \%params );
}

# Detect read-only queries
sub _is_readonly {
    my $sql = shift;
    return 0 unless defined $sql;

    # SELECT or WITH ... SELECT (CTE)
    return $sql =~ /^\s*(SELECT|WITH\s+\w+.*?\bSELECT)\b/si ? 1 : 0;
}

# Main connect function - returns a DBD::Patroni::db object
sub connect {
    my ( $class, $dsn, $user, $pass, $attr ) = @_;

    $attr //= {};

    # Parse DSN for Patroni parameters
    my ( $clean_dsn, $dsn_params ) = _parse_dsn($dsn);
    $dsn = $clean_dsn;

    # Extract Patroni-specific attributes (attr takes precedence over DSN)
    my $patroni_url = delete $attr->{patroni_url} // $dsn_params->{patroni_url};
    my $patroni_lb  = delete $attr->{patroni_lb}  // $dsn_params->{patroni_lb}
      // 'round_robin';
    my $patroni_timeout = delete $attr->{patroni_timeout}
      // $dsn_params->{patroni_timeout} // 3;

    die "DBD::Patroni: patroni_url attribute is required\n"
      unless $patroni_url;

    # Discover cluster
    my ( $leader, @replicas ) =
      _discover_cluster( $patroni_url, $patroni_timeout );

    # Build leader DSN
    my $leader_dsn = $dsn;
    $leader_dsn =~ s/(?:host|port)=[^;]*;?//gi;
    $leader_dsn .= ";host=$leader->{host};port=$leader->{port}";

    # Connect to leader
    my $leader_dbh =
      DBI->connect( "dbi:Pg:$leader_dsn", $user, $pass,
        { %$attr, RaiseError => 1 } )
      or die "DBD::Patroni: Cannot connect to leader: $DBI::errstr\n";

    # Connect to replica (if available and not leader_only mode)
    my $replica_dbh;
    if ( @replicas && $patroni_lb ne 'leader_only' ) {
        my $replica = _select_replica( \@replicas, $patroni_lb );
        if ($replica) {
            my $replica_dsn = $dsn;
            $replica_dsn =~ s/(?:host|port)=[^;]*;?//gi;
            $replica_dsn .= ";host=$replica->{host};port=$replica->{port}";

            $replica_dbh = eval {
                DBI->connect( "dbi:Pg:$replica_dsn", $user, $pass,
                    { %$attr, RaiseError => 1 } );
            };
            warn "DBD::Patroni: Cannot connect to replica, using leader: $@\n"
              if $@ && !$replica_dbh;
        }
    }
    $replica_dbh //= $leader_dbh;

    # Create and return the wrapper object
    return DBD::Patroni::db->new(
        leader_dbh  => $leader_dbh,
        replica_dbh => $replica_dbh,
        config      => {
            dsn             => $dsn,
            user            => $user,
            pass            => $pass,
            attr            => $attr,
            patroni_url     => $patroni_url,
            patroni_lb      => $patroni_lb,
            patroni_timeout => $patroni_timeout,
        },
    );
}

# Cached connect function - uses DBI->connect_cached for underlying connections
sub connect_cached {
    my ( $class, $dsn, $user, $pass, $attr ) = @_;

    $attr //= {};

    # Parse DSN for Patroni parameters
    my ( $clean_dsn, $dsn_params ) = _parse_dsn($dsn);
    $dsn = $clean_dsn;

    # Extract Patroni-specific attributes (attr takes precedence over DSN)
    my $patroni_url = delete $attr->{patroni_url} // $dsn_params->{patroni_url};
    my $patroni_lb  = delete $attr->{patroni_lb}  // $dsn_params->{patroni_lb}
      // 'round_robin';
    my $patroni_timeout = delete $attr->{patroni_timeout}
      // $dsn_params->{patroni_timeout} // 3;

    die "DBD::Patroni: patroni_url attribute is required\n"
      unless $patroni_url;

    # Discover cluster
    my ( $leader, @replicas ) =
      _discover_cluster( $patroni_url, $patroni_timeout );

    # Build leader DSN
    my $leader_dsn = $dsn;
    $leader_dsn =~ s/(?:host|port)=[^;]*;?//gi;
    $leader_dsn .= ";host=$leader->{host};port=$leader->{port}";

    # Connect to leader using DBI's cached connection mechanism
    my $leader_dbh =
      DBI->connect_cached( "dbi:Pg:$leader_dsn", $user, $pass,
        { %$attr, RaiseError => 1, private_patroni_role => 'leader' } )
      or die "DBD::Patroni: Cannot connect to leader: $DBI::errstr\n";

    # Connect to replica (if available and not leader_only mode)
    my $replica_dbh;
    if ( @replicas && $patroni_lb ne 'leader_only' ) {
        my $replica = _select_replica( \@replicas, $patroni_lb );
        if ($replica) {
            my $replica_dsn = $dsn;
            $replica_dsn =~ s/(?:host|port)=[^;]*;?//gi;
            $replica_dsn .= ";host=$replica->{host};port=$replica->{port}";

            $replica_dbh = eval {
                DBI->connect_cached(
                    "dbi:Pg:$replica_dsn",
                    $user, $pass,
                    {
                        %$attr,
                        RaiseError           => 1,
                        private_patroni_role => 'replica'
                    }
                );
            };
            warn "DBD::Patroni: Cannot connect to replica, using leader: $@\n"
              if $@ && !$replica_dbh;
        }
    }
    $replica_dbh //= $leader_dbh;

    # Create and return the wrapper object
    return DBD::Patroni::db->new(
        leader_dbh  => $leader_dbh,
        replica_dbh => $replica_dbh,
        config      => {
            dsn             => $dsn,
            user            => $user,
            pass            => $pass,
            attr            => $attr,
            patroni_url     => $patroni_url,
            patroni_lb      => $patroni_lb,
            patroni_timeout => $patroni_timeout,
            use_cached      => 1,
        },
    );
}

1;

# Database handle wrapper
package DBD::Patroni::db;

use strict;
use warnings;

sub new {
    my ( $class, %args ) = @_;
    return bless {
        leader_dbh  => $args{leader_dbh},
        replica_dbh => $args{replica_dbh},
        config      => $args{config},
    }, $class;
}

# Execute with automatic retry on failure
sub _with_retry {
    my ( $self, $target, $code ) = @_;
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
                $self->_rediscover_cluster();
                next;
            }
            die $error;
        }
        return $wantarray ? @results : $result;
    }
}

sub _is_connection_error {
    my $error = shift;
    return 0 unless $error;

    # # Connection-related error patterns
    # connection refused
    # connection reset
    # could not connect
    # server closed the connection
    # no connection to the server
    # terminating connection
    # connection timed out
    # lost connection

    # # Read-only errors indicate we're connected to a replica instead of leader
    #  read-only transaction
    #  cannot execute .* in a read-only transaction

    # # PostgreSQL recovery/startup errors (node not ready after failover)
    # the database system is starting up
    # the database system is in recovery mode
    # the database system is shutting down/
    # recovery is in progress
    # not accepting connections
    # hot standby mode is disabled
    return 1
      if $error =~
/(?:c(?:o(?:nnection (?:re(?:fused|set)|timed out)|uld not connect)|annot execute .* in a read-only transaction)|t(?:he database system is (?:s(?:hutting down|tarting up)|in recovery mode)|erminating connection)|no(?: connection to the server|t accepting connections)|re(?:covery is in progress|ad-only transaction)|(?:server closed the|lost) connection|hot standby mode is disabled)/;

    return 0;
}

sub _rediscover_cluster {
    my $self   = shift;
    my $config = $self->{config};

    # Close old connections
    eval { $self->{leader_dbh}->disconnect } if $self->{leader_dbh};
    if ( $self->{replica_dbh} && $self->{replica_dbh} ne $self->{leader_dbh} ) {
        eval { $self->{replica_dbh}->disconnect };
    }

    # Rediscover cluster
    my ( $leader, @replicas ) =
      DBD::Patroni::_discover_cluster( $config->{patroni_url},
        $config->{patroni_timeout} );

    # Rebuild leader DSN
    my $leader_dsn = $config->{dsn};
    $leader_dsn =~ s/(?:host|port)=[^;]*;?//gi;
    $leader_dsn .= ";host=$leader->{host};port=$leader->{port}";

    # Reconnect to leader
    $self->{leader_dbh} =
      DBI->connect( "dbi:Pg:$leader_dsn", $config->{user}, $config->{pass},
        { %{ $config->{attr} }, RaiseError => 1 } )
      or die "DBD::Patroni: Cannot reconnect to leader: $DBI::errstr\n";

    # Reconnect to replica
    if ( @replicas && $config->{patroni_lb} ne 'leader_only' ) {
        my $replica =
          DBD::Patroni::_select_replica( \@replicas, $config->{patroni_lb} );
        if ($replica) {
            my $replica_dsn = $config->{dsn};
            $replica_dsn =~ s/(?:host|port)=[^;]*;?//gi;
            $replica_dsn .= ";host=$replica->{host};port=$replica->{port}";

            $self->{replica_dbh} = eval {
                DBI->connect( "dbi:Pg:$replica_dsn", $config->{user},
                    $config->{pass},
                    { %{ $config->{attr} }, RaiseError => 1 } );
            };
        }
    }
    $self->{replica_dbh} //= $self->{leader_dbh};
}

sub prepare {
    my ( $self, $statement, @attribs ) = @_;

    return undef unless defined $statement;

    my $is_readonly = DBD::Patroni::_is_readonly($statement);
    my $target      = $is_readonly ? 'replica'            : 'leader';
    my $target_dbh  = $is_readonly ? $self->{replica_dbh} : $self->{leader_dbh};

    my $real_sth = $target_dbh->prepare( $statement, @attribs );
    return undef unless $real_sth;

    return DBD::Patroni::st->new(
        real_sth  => $real_sth,
        target    => $target,
        statement => $statement,
        db        => $self,
    );
}

sub do {
    my ( $self, $statement, $attr, @bind ) = @_;
    my $is_readonly = DBD::Patroni::_is_readonly($statement);
    my $target      = $is_readonly ? 'replica' : 'leader';

    my $result = eval {
        $self->_with_retry(
            $target,
            sub {
                my $handle =
                  $is_readonly ? $self->{replica_dbh} : $self->{leader_dbh};
                return $handle->do( $statement, $attr, @bind );
            }
        );
    };

    if ($@) {
        my $error = $@;

        # Store error for errstr
        $self->{_last_error} = $error;

        # Check if user wants exceptions
        my $raise_error = $self->{config}{attr}{RaiseError} // 1;
        if ($raise_error) {
            die $error;
        }
        return undef;
    }
    return $result;
}

sub ping {
    my $self = shift;
    return $self->{leader_dbh}->ping;
}

sub disconnect {
    my $self = shift;
    $self->{leader_dbh}->disconnect if $self->{leader_dbh};
    if ( $self->{replica_dbh} && $self->{replica_dbh} ne $self->{leader_dbh} ) {
        $self->{replica_dbh}->disconnect;
    }
    return 1;
}

# Transactions: always on leader
sub begin_work { shift->{leader_dbh}->begin_work }
sub commit     { shift->{leader_dbh}->commit }
sub rollback   { shift->{leader_dbh}->rollback }

# Delegate common methods to leader
sub quote              { shift->{leader_dbh}->quote(@_) }
sub quote_identifier   { shift->{leader_dbh}->quote_identifier(@_) }
sub last_insert_id     { shift->{leader_dbh}->last_insert_id(@_) }
sub table_info         { shift->{leader_dbh}->table_info(@_) }
sub column_info        { shift->{leader_dbh}->column_info(@_) }
sub primary_key_info   { shift->{leader_dbh}->primary_key_info(@_) }
sub foreign_key_info   { shift->{leader_dbh}->foreign_key_info(@_) }
sub tables             { shift->{leader_dbh}->tables(@_) }
sub selectrow_array    { shift->{leader_dbh}->selectrow_array(@_) }
sub selectrow_arrayref { shift->{leader_dbh}->selectrow_arrayref(@_) }
sub selectrow_hashref  { shift->{leader_dbh}->selectrow_hashref(@_) }
sub selectall_arrayref { shift->{leader_dbh}->selectall_arrayref(@_) }
sub selectall_hashref  { shift->{leader_dbh}->selectall_hashref(@_) }
sub selectcol_arrayref { shift->{leader_dbh}->selectcol_arrayref(@_) }

sub errstr {
    my $self = shift;
    return $self->{_last_error} || $self->{leader_dbh}->errstr;
}
sub err   { shift->{leader_dbh}->err }
sub state { shift->{leader_dbh}->state }

# Attribute accessors
sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    return if $method eq 'DESTROY';

    # Delegate to leader handle
    if ( $self->{leader_dbh}->can($method) ) {
        return $self->{leader_dbh}->$method(@_);
    }

    die "DBD::Patroni::db: Unknown method '$method'\n";
}

sub DESTROY {
    my $self = shift;
    $self->disconnect if $self->{leader_dbh};
}

1;

# Statement handle wrapper
package DBD::Patroni::st;

use strict;
use warnings;

sub new {
    my ( $class, %args ) = @_;
    return bless {
        real_sth  => $args{real_sth},
        target    => $args{target},
        statement => $args{statement},
        db        => $args{db},
    }, $class;
}

sub execute {
    my ( $self, @bind ) = @_;
    my $db     = $self->{db};
    my $target = $self->{target};

    return $db->_with_retry(
        $target,
        sub {
            # Check if statement handle is still valid
            my $real_sth = $self->{real_sth};
            unless ( $real_sth
                && $real_sth->{Database}
                && $real_sth->{Database}{Active} )
            {
                # Re-prepare statement after reconnection
                my $handle =
                    $target eq 'replica'
                  ? $db->{replica_dbh}
                  : $db->{leader_dbh};
                $self->{real_sth} = $handle->prepare( $self->{statement} );
                $real_sth = $self->{real_sth};
            }
            return $real_sth->execute(@bind);
        }
    );
}

# Delegate fetch methods
sub fetch             { shift->{real_sth}->fetch }
sub fetchrow_array    { shift->{real_sth}->fetchrow_array }
sub fetchrow_arrayref { shift->{real_sth}->fetchrow_arrayref }
sub fetchrow_hashref  { shift->{real_sth}->fetchrow_hashref(@_) }
sub fetchall_arrayref { shift->{real_sth}->fetchall_arrayref(@_) }
sub fetchall_hashref  { shift->{real_sth}->fetchall_hashref(@_) }
sub finish            { shift->{real_sth}->finish }
sub rows              { shift->{real_sth}->rows }
sub bind_param        { shift->{real_sth}->bind_param(@_) }
sub bind_param_inout  { shift->{real_sth}->bind_param_inout(@_) }
sub bind_col          { shift->{real_sth}->bind_col(@_) }
sub bind_columns      { shift->{real_sth}->bind_columns(@_) }

sub errstr { shift->{real_sth}->errstr }
sub err    { shift->{real_sth}->err }
sub state  { shift->{real_sth}->state }

# Attribute accessors via AUTOLOAD
sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    return if $method eq 'DESTROY';

    # Delegate to real statement handle
    if ( $self->{real_sth}->can($method) ) {
        return $self->{real_sth}->$method(@_);
    }

    die "DBD::Patroni::st: Unknown method '$method'\n";
}

sub DESTROY {
    my $self = shift;
    $self->{real_sth}->finish if $self->{real_sth};
}

1;

__END__

=head1 NAME

DBD::Patroni - DBI driver for PostgreSQL with Patroni cluster support

=head1 SYNOPSIS

    use DBD::Patroni;

    # Option 1: Patroni parameters in attributes hash
    my $dbh = DBD::Patroni->connect(
        "dbname=mydb",
        $user, $password,
        {
            patroni_url => "http://patroni1:8008/cluster,http://patroni2:8008/cluster",
            patroni_lb  => "round_robin",  # round_robin | random | leader_only
        }
    );

    # Option 2: Patroni parameters in DSN string
    my $dbh = DBD::Patroni->connect(
        "dbname=mydb;patroni_url=http://patroni1:8008/cluster;patroni_lb=round_robin",
        $user, $password
    );

    # SELECT queries go to replica
    my $sth = $dbh->prepare("SELECT * FROM users WHERE id = ?");
    $sth->execute(1);

    # INSERT/UPDATE/DELETE queries go to leader
    $dbh->do("INSERT INTO users (name) VALUES (?)", undef, "John");

    $dbh->disconnect;

=head1 DESCRIPTION

DBD::Patroni is a wrapper around DBD::Pg that provides automatic
routing of queries to the appropriate node in a Patroni-managed PostgreSQL
cluster.

=head2 Features

=over 4

=item * Automatic leader discovery via Patroni REST API

=item * Read queries (SELECT) routed to replicas

=item * Write queries (INSERT, UPDATE, DELETE) routed to leader

=item * Configurable load balancing for replicas

=item * Automatic failover with retry on connection errors

=back

=head1 CONNECTION

Unlike standard DBI drivers, DBD::Patroni uses a direct connect method:

    my $dbh = DBD::Patroni->connect($dsn, $user, $pass, \%attr);

The DSN should be a PostgreSQL DSN without the C<dbi:Pg:> prefix. All
standard L<DBD::Pg> connection parameters are supported (host, port,
dbname, sslmode, etc.). See L<DBD::Pg> for a complete list of options.

Patroni-specific parameters (C<patroni_url>, C<patroni_lb>, C<patroni_timeout>)
can be passed either in the DSN string or in the attributes hash. If specified
in both places, the attributes hash takes precedence.

Example with Patroni parameters in DSN:

    my $dbh = DBD::Patroni->connect(
        "dbname=mydb;sslmode=disable;patroni_url=http://patroni:8008/cluster",
        $user, $password
    );

Example with Patroni parameters in attributes:

    my $dbh = DBD::Patroni->connect(
        "dbname=mydb;sslmode=disable",
        $user, $password,
        { patroni_url => "http://patroni:8008/cluster" }
    );

=head1 CONNECTION ATTRIBUTES

These attributes can be specified either in the DSN string or in the
attributes hash. If specified in both places, the attributes hash takes
precedence.

=over 4

=item patroni_url (required)

Comma-separated list of Patroni REST API endpoints.

=item patroni_lb

Load balancing mode for replicas:

=over 4

=item * C<round_robin> (default): Cycle through available replicas

=item * C<random>: Select a random replica

=item * C<leader_only>: Always use the leader (no read scaling)

=back

=item patroni_timeout

HTTP timeout in seconds for Patroni API calls. Default: 3

=back

=head1 QUERY ROUTING

Queries are automatically routed based on their type:

=over 4

=item * B<SELECT> and B<WITH...SELECT> queries go to a replica

=item * B<INSERT>, B<UPDATE>, B<DELETE>, B<CREATE>, B<DROP>, etc. go to the leader

=back

=head1 FAILOVER

On connection failure, DBD::Patroni will:

=over 4

=item 1. Query the Patroni API to discover the current leader

=item 2. Reconnect to the new leader/replica

=item 3. Retry the failed operation

=back

If the retry also fails, the error is propagated to the caller.

=head1 SEE ALSO

L<DBD::Pg> - The underlying PostgreSQL driver

L<DBI> - Database independent interface for Perl

=head1 AUTHOR

Xavier Guimard

=head1 LICENSE

Same as Perl itself.

=cut
