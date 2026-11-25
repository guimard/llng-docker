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
# never share a transaction. Without Commit, or with a Handle, nothing changes.
our %IDLE;          # "datasource\0user" => [ [ $dbh, $pid ], ... ]
our $MAX_IDLE = 4;  # idle connections kept per data source and process

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
        my ( $handle, $pid ) = @$idle;
        if ( $pid != $$ ) {

            # inherited from the parent before a fork: its socket is the
            # parent's, never use nor close it here
            $handle->{InactiveDestroy} = 1;
            next;
        }
        if ( eval { $handle->ping } ) {
            $dbh = $handle;
            last;
        }
        eval { $handle->disconnect };
    }
    $dbh ||= DBI->connect( $datasource, $username, $password,
        { RaiseError => 1, AutoCommit => 0 } )
      || die $DBI::errstr;
    $dbh->{pg_enable_utf8} = 1;
    $self->{dbh}        = $dbh;
    $self->{pool_key}   = $key;
    $self->{commit}     = $args->{Commit};
    $self->{disconnect} = 0;
}

sub DESTROY {
    my $self = shift;
    my $key  = $self->{pool_key};
    return $self->SUPER::DESTROY(@_) unless defined $key;
    my $dbh = delete $self->{dbh} or return;

    # the end of this store's transaction, as Apache::Session::Store::Postgres
    # ends it (commit), then the connection goes back to the idle ones; one
    # that failed to commit, or found at the end of the program, is closed
    my $ended = eval { $dbh->commit; 1 };
    if (   $ended
        && ${^GLOBAL_PHASE} ne 'DESTRUCT'
        && @{ $IDLE{$key} ||= [] } < $MAX_IDLE )
    {
        push @{ $IDLE{$key} }, [ $dbh, $$ ];
        return;
    }
    eval { $dbh->disconnect };
}

1;
