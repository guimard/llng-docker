package Apache::Session::Browseable::Store::Postgres;

use strict;

use Apache::Session::Browseable::Store::DBI;
use Apache::Session::Store::Postgres;

our @ISA =
  qw(Apache::Session::Browseable::Store::DBI Apache::Session::Store::Postgres);
our $VERSION = '1.2.2';

# Apache::Session::Store::Postgres connects in every store (one per tied
# session) and disconnects in its DESTROY: a PostgreSQL backend forked and
# authenticated for each session transaction, several per login. When the
# stores commit (Commit set) and no Handle is given, the connections are kept
# here instead, per process and per data source, and lent to one store at a
# time: two sessions tied together (a session and its persistent session)
# never share a connection. Without Commit, or with a Handle, nothing changes.
#
# On that path each statement is its own transaction (AutoCommit): the store
# reads without a lock (Apache::Session::Store::DBI's materialize, no FOR
# UPDATE; the lock manager is Null), and a tie writes once, so a transaction
# around it protected nothing and cost a BEGIN and a COMMIT round trip each.
# That once: a new session is inserted at its tie, then updated at its untie
# with its data (Apache::Session's TIEHASH saves a new session at once); here
# the insert waits for the untie and writes the data then, a single INSERT.
our %IDLE;          # "datasource\0user" => [ [ $dbh, $pid, $since ], ... ]
our $MAX_IDLE = 4;  # idle connections kept per data source and process
our $PING_AFTER = 30;    # seconds idle: a handle older than this is pinged

# Whether an idle handle can be lent without a round trip: one given back
# lately, its statements done, whose socket has nothing to read, is alive (a
# server that goes away closes it, which makes it readable). One idle for
# longer, one whose socket is readable or unknown, is pinged as before.
sub _usable {
    my ( $handle, $since ) = @_;
    return 0 unless $handle->{Active};
    my $fd = eval { $handle->{pg_socket} };
    if ( time - ( $since // 0 ) < $PING_AFTER and defined $fd and $fd >= 0 ) {
        my $rin = '';
        vec( $rin, $fd, 1 ) = 1;
        # the descriptor number only: no Perl handle opened, none closed
        my $ready = select( my $rout = $rin, undef, undef, 0 );
        return 1 if defined $ready and $ready == 0;
    }
    return eval { $handle->ping } ? 1 : 0;
}

sub connection {
    my ( $self, $session ) = @_;
    return if defined $self->{dbh};
    my $args = $session->{args};
    if ( exists $args->{Handle} or !$args->{Commit} ) {
        $self->SUPER::connection($session);
        $self->{dbh}->{pg_enable_utf8} = 1;
        return;
    }
    $self->{table_name} =
      $args->{TableName} || $Apache::Session::Store::DBI::TableName;
    my $datasource = $args->{DataSource}
      || $Apache::Session::Store::Postgres::DataSource;
    my $username = $args->{UserName}
      || $Apache::Session::Store::Postgres::UserName;
    my $password = $args->{Password}
      || $Apache::Session::Store::Postgres::Password;
    my $key = join "\0", $datasource // '', $username // '';
    my $dbh;
    while ( my $idle = pop @{ $IDLE{$key} ||= [] } ) {
        my ( $handle, $pid, $since ) = @$idle;
        if ( $pid != $$ ) {

            # inherited from the parent before a fork: its socket is the
            # parent's, never use nor close it here
            $handle->{InactiveDestroy} = 1;
            next;
        }
        if ( _usable( $handle, $since ) ) {
            $dbh = $handle;
            last;
        }
        eval { $handle->disconnect };
    }
    $dbh ||= DBI->connect( $datasource, $username, $password,
        { RaiseError => 1, AutoCommit => 1 } )
      || die $DBI::errstr;
    $dbh->{pg_enable_utf8} = 1;
    $self->{dbh}        = $dbh;
    $self->{pool_key}   = $key;
    $self->{commit}     = $args->{Commit};
    $self->{disconnect} = 0;
}

# a new session: its insert waits for the untie (the update that follows), so
# that it is written once, with its data
sub insert {
    my ( $self, $session ) = @_;
    $self->connection($session);
    return $self->SUPER::insert($session) unless defined $self->{pool_key};

    # what the insert needs, copied: keeping $session would be a cycle (it
    # holds this store), and neither would ever be destroyed
    $self->{pending_insert} = {
        data       => { %{ $session->{data} } },
        serialized => $session->{serialized},
        args       => $session->{args},
    };
    return 1;
}

sub update {
    my ( $self, $session ) = @_;
    return $self->SUPER::insert($session) if delete $self->{pending_insert};
    return $self->SUPER::update($session);
}

sub remove {
    my ( $self, $session ) = @_;

    # created and removed in the same tie: nothing was written
    return 1 if delete $self->{pending_insert};
    return $self->SUPER::remove($session);
}

sub DESTROY {
    my $self = shift;
    my $key  = $self->{pool_key};
    return $self->SUPER::DESTROY(@_) unless defined $key;
    my $dbh = $self->{dbh} or return;

    # a new session untied without an update: inserted now, as it was tied
    my $ended = 1;
    if ( my $pending = delete $self->{pending_insert} ) {
        $ended = eval { $self->SUPER::insert($pending); 1 };
        print STDERR "Unable to store the new session: $@" unless $ended;
    }
    delete $self->{dbh};

    # each statement committed itself (AutoCommit): the connection goes back
    # to the idle ones; one that failed, or found at the end of the program, is
    # closed
    $ended &&= $dbh->{AutoCommit} || eval { $dbh->commit; 1 };
    if (   $ended
        && ${^GLOBAL_PHASE} ne 'DESTRUCT'
        && @{ $IDLE{$key} ||= [] } < $MAX_IDLE )
    {
        push @{ $IDLE{$key} }, [ $dbh, $$, time ];
        return;
    }
    eval { $dbh->disconnect };
}

1;
