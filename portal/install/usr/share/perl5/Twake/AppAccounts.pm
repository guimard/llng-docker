package Twake::AppAccounts;

use strict;
use List::Util   qw(shuffle);
use MIME::Base64 qw/encode_base64/;
use Mouse;
use String::Random;

use Lemonldap::NG::Portal::Main::Constants qw(
  portalConsts
  PE_ERROR
  PE_LDAPCONNECTFAILED
  PE_LDAPERROR
);

# CONSTANTS AND PARAMETERS
use constant MAX_ACCOUNTS => 5;

our $prefix = __PACKAGE__;

# Inheritance
extends qw(
  Lemonldap::NG::Portal::Lib::LDAP
  Lemonldap::NG::Portal::Main::Plugin
);

# Properties
has validTokens => ( is => 'rw' );

has fieldsToMap =>
  ( is => 'rw', default => sub { [qw(cn displayName mail sn)] } );

# Password entropy
our $gen = String::Random->new;
$gen->set_pattern(
    A => [
        'A' .. 'H',
        qw(J K M N),
        'P' .. 'Z',
        'a' .. 'h',
        qw(j k m n),
        'p' .. 'z',
        '2' .. '9'
    ]
);

$gen->set_pattern( S => [qw[@ ( ) / : ; ! ?]] );

# INITIALIZATION METHOD
sub init {
    my ($self) = @_;

    unless ( $self->conf->{twakeAppLdapBranch} ) {
        $self->logger->error('Missing twakeAppLdapBranch');
        return 0;
    }

    if ( $self->conf->{twakeAdminTokens} ) {
        my $str = '^(?:'
          . join( '|',
            map { "\\Q$_\\E" } split /[;,\s]\s*/,
            $self->conf->{twakeAdminTokens} ) . ')$';
        $self->validTokens(qr/$str/);
    }
    if ( $self->conf->{twakeAppEntryFields} ) {
        $self->fieldsToMap( split /[;,\s]\s*/,
            $self->conf->{twakeAppEntryFields} );
    }

    # Catch /deviceaccounts url and launch "deviceAccounts" metho
    $self->addAuthRoute(
        deviceaccounts => { '*' => 'deviceAccounts' },
        ['GET']
      )

      # If user isn't connected, create redirection after auth
      ->addUnauthRoute( deviceaccounts => 'connect', ['GET'] )

      # App accounts
      ->addAuthRoute(
        deviceaccounts => { list => 'listAccounts' },
        ['GET']
      )

      ->addAuthRoute(
        deviceaccounts => { add => 'addAccount', del => 'delAccount' },
        ['POST']
      )

      # App accounts for scripts
      ->addUnauthRoute(
        deviceaccounts => {
            add  => 'addAccountByToken',
            del  => 'delAccountByToken',
            list => 'listAccountsByToken'
        },
        ['POST']
      );
    return 1;
}

sub connect {
    my $portal = $_[0]->conf->{portal};
    $portal =~ s#/$##;
    return [
        302,
        [
                Location => $portal
              . '/?url='
              . encode_base64( $portal . '/deviceaccounts' )
        ],
        []
    ];
}

# Display IMAP accounts
#
# HTML response
sub deviceAccounts {
    my ( $self, $req ) = @_;

    return $self->p->sendHtml(
        $req,
        'displayAppAccounts',
        params => {
            AUTH_USER => $req->userData->{ $self->conf->{portalUserAttr} },
            TOKEN     => $self->p->stamp,
        }
    );
}

sub listAccountsByToken {
    return $_[0]->apiCall( $_[1], 'listAccounts' );
}

sub listAccounts {
    my ( $self,     $req ) = @_;
    my ( $accounts, $err ) = $self->getAccounts($req);
    return $err unless $accounts;
    return $self->p->sendJSONresponse( $req, $accounts );
}

# Add an IMAP account
#
# API only
#
# @param token
# @return new uid
sub addAccountByToken {
    return $_[0]->apiCall( $_[1], 'addAccount' );
}

sub addAccount {
    my ( $self, $req, $api ) = @_;

    #my $query = $api ? $req->jsonBodyToObj : $self->getContent($req);
    my $query = $req->jsonBodyToObj;

    return $self->sendError( $req, 'Bad content', PE_ERROR, 400 )
      unless $query;

    my ( $accounts, $err ) = $self->getAccounts($req);
    return $err unless $accounts;
    return $self->sendError( $req, 'Too many accounts', PE_ERROR, 400 )
      if !$req->data->{skipMaxAccounts} and scalar(@$accounts) >= MAX_ACCOUNTS;
    my @uids = map { $_->{uid} } @$accounts;

    my $newAccount;

    #my $gen = String::Random->new;
    do {
        $newAccount = $gen->randpattern( 'c' . 'n' x 8 );
    } while ( grep { $_ eq $newAccount } @uids );

    my $uid = $req->userData->{uid} . "_$newAccount";
    $query->{name} =~ s/^HIDDEN__// if defined $query->{name};
    if ( $req->data->{skipMaxAccounts} ) {
        $query->{name} = 'HIDDEN__' . ( $query->{name} // '' );
    }
    my $newEntry = [
        objectclass => ['inetOrgPerson'],
        ( $query->{name} ? ( description => $query->{name} ) : () ),
    ];
    foreach ( @{ $self->fieldsToMap } ) {
        push @$newEntry, $_ => $req->userData->{$_}
          if defined $req->userData->{$_};
    }

    # 4 blocks of 4 random chars, separated by "-"
    my $newPwd = join '-', shuffle map {
        join '', shuffle split //,
          $gen->randpattern(
            ( $_ < 2 or ( $_ == 3 && int( rand(2) ) ) > 0 ) ? 'AASA' : 'AAAA' )
    } ( 1 .. 4 );

    my $ldapPwd = $self->ldapPwd($newPwd);
    push @$newEntry, userPassword => $ldapPwd;
    my @outlookEntry;
    for ( my $i = 0 ; $i < @$newEntry ; $i += 2 ) {
        push @outlookEntry, $newEntry->[$i], $newEntry->[ $i + 1 ]
          unless $newEntry->[$i] eq 'uid';
    }
    push @$newEntry, uid => $uid;
    my $mesg =
      $self->ldap->add( "uid=$uid," . $self->conf->{twakeAppLdapBranch},
        attrs => $newEntry );
    return $self->sendError( $req,
        "$prefix LDAP Add error " . $mesg->code . ': ' . $mesg->error,
        PE_LDAPERROR )
      if $mesg->code;
    $mesg = $self->ldap->search(
        base   => $self->conf->{twakeAppLdapBranch},
        scope  => 'sub',
        filter => '(uid=' . $req->userData->{mail} . ')',
        deref  => 'find',
    );
    push @outlookEntry, uid => $req->userData->{mail};
    my $dn =
      'uid=' . $req->userData->{mail} . ',' . $self->conf->{twakeAppLdapBranch};
    my @tmp = eval { $mesg->entries };

    if ( $mesg->code() != 0 or !@tmp ) {

        # First account, let's create the Outlook account
        $mesg = $self->ldap->add( $dn, attrs => \@outlookEntry );
        $self->logger->error( "$prefix LDAP Add error (Outlook account) "
              . $mesg->code . ': '
              . $mesg->error )
          if $mesg->code;
    }
    else {
        $self->ldap->modify( $dn, add => { userPassword => $ldapPwd } );
        $self->logger->error( "$prefix LDAP Modify error (Outlook account) "
              . $mesg->code . ': '
              . $mesg->error )
          if $mesg->code;
    }

    return $self->p->sendJSONresponse( $req,
        { uid => $uid, pwd => $newPwd, mail => $req->userData->{mail} } );
}

sub ldapPwd {
    my ( $self, $pwd ) = @_;
    my $salt  = '';
    my @chars = ( 'a' .. 'z', 'A' .. 'Z', '0' .. '9', '.', '/' );
    for ( 1 .. 4 ) {
        $salt .= $chars[ rand @chars ];
    }
    my $sha = Digest::SHA->new('sha1');
    $sha->add( $pwd . $salt );
    my $digest = $sha->digest;
    return "{SSHA}" . encode_base64( $digest . $salt, '' );
}

# Delete IMAP account
#
# @param token
# @param uid
# @return deleted uid
sub delAccountByToken {
    return $_[0]->apiCall( $_[1], 'delAccount' );
}

sub delAccount {
    my ( $self, $req, $api ) = @_;

    #my $query = $api ? $req->jsonBodyToObj : $self->getContent($req);
    my $query = $req->jsonBodyToObj;

    return $self->sendError( $req, 'Bad content', PE_ERROR, 400 )
      unless $query;

    my $accounts = $self->getAccounts($req);
    return $self->sendError( $req, 'No accounts', PE_ERROR, 400 )
      if scalar(@$accounts) == 0;

    my $mesg = $self->ldap->search(
        base   => $self->conf->{twakeAppLdapBranch},
        scope  => 'sub',
        filter => "(uid=$query->{uid})",
        deref  => 'find',
    );
    if ( $mesg->code() != 0 ) {
        $self->userLogger->error("Account $query->{uid} already deleted");
        return $self->p->sendJSONresponse( $req, { uid => $query->{uid} } );
    }
    my ($entry) = $mesg->entries;
    return $self->sendError( $req, 'No such accounts', PE_ERROR, 400 )
      unless $entry;
    my $passwordToDelete = $entry->get_value('userPassword');

    # TODO
    my $outlookDn = $req->userData->{mail};
    $outlookDn = "uid=$outlookDn," . $self->conf->{twakeAppLdapBranch};
    $mesg      = $self->ldap->modify(
        $outlookDn,
        delete => {
            userPassword => $passwordToDelete,
        }
    );
    $self->logger->error( "$prefix LDAP Delete error (Outlook) "
          . $mesg->code . ': '
          . $mesg->error )
      if $mesg->code;

    $mesg = $self->ldap->delete(
        "uid=$query->{uid}," . $self->conf->{twakeAppLdapBranch} );
    return $self->sendError( $req,
        "$prefix LDAP Delete error " . $mesg->code . ': ' . $mesg->error,
        PE_LDAPERROR )
      if $mesg->code;

    return $self->p->sendJSONresponse( $req, { uid => $query->{uid} } );
}

# INTERNAL METHODS

# Get IMAP accounts list
sub getAccounts {
    my ( $self, $req ) = @_;
    $self->validateLdap;
    return ( 0,
        $self->sendError( $req, "$prefix LDAP error", PE_LDAPCONNECTFAILED ) )
      unless $self->ldap and $self->bind();

    my $mail = $req->userData->{mail}
      or return (
        0,
        $self->sendError(
            $req,         "$prefix Unable to find mail",
            PE_LDAPERROR, 500
        )
      );

    my @accounts;

    my $mesg = $self->ldap->search(
        base   => $self->conf->{twakeAppLdapBranch},
        scope  => 'sub',
        filter => "(mail=$mail)",
        deref  => 'find',
    );
    $self->logger->debug( "Look to $mail IMAP accounts, (mail=$mail) into "
          . $self->conf->{twakeAppLdapBranch} );
    my $count = 0;
    return (
        0,
        $self->sendError(
            $req,
            "$prefix LDAP Search error " . $mesg->code . ': ' . $mesg->error,
            PE_LDAPERROR
        )
    ) if $mesg->code() != 0;

    $count = $mesg->count;

    foreach ( $mesg->entries ) {
        my $desc = $_->get_value('description');
        push @accounts,
          { uid => $_->get_value('uid'), $desc ? ( name => $desc ) : () }
          unless $_->get_value('uid') eq $req->userData->{uid}
          or $_->get_value('uid') eq $req->userData->{mail};
    }
    @accounts = sort { $a->{uid} cmp $b->{uid} } @accounts;
    unless ( $req->data->{skipMaxAccounts} ) {
        @accounts = grep { !$_->{name} or $_->{name} !~ /^HIDDEN__/ } @accounts;
    }
    return \@accounts;
}

# Manage error display
sub sendError {
    my ( $self, $req, $logMsg, $errCode, $serverErrCode ) = @_;
    $errCode       ||= PE_ERROR;
    $serverErrCode ||= 500;
    return $self->p->sendError( $req, $logMsg, $serverErrCode )
      if $req->wantJSON;
    $self->logger->error("$prefix $logMsg");
    return $self->p->sendHtml(
        $req,
        'displayLdapAccounts',
        params => {
            AUTH_ERROR      => $errCode,
            AUTH_ERROR_TYPE => 'warning',
            TOKEN           => $self->p->stamp,
        }
    );
}

# For POST requests, verify token and return JSON content unserialized
sub getContent {
    my ( $self, $req ) = @_;
    my $query = $req->jsonBodyToObj;

    return undef
      unless $query
      and ref $query eq 'HASH'
      and $query->{token};
    my $time = time() - $self->conf->{cipher}->decrypt( $query->{token} );
    return undef unless $time < 3600;
    return $query;
}

sub apiCall {
    my ( $self, $req, $sub ) = @_;

    # 1 - Check for authorization
    if ( my $tmp = $self->missingToken($req) ) { return $tmp }

    # Get user
    my $body = $req->jsonBodyToObj;
    return $self->p->sendError( $req, 'Empty body',   400 ) unless $body;
    return $self->p->sendError( $req, 'Missing user', 400 )
      unless $body->{user};
    $req->user( $body->{user} );

    # Build user
    $req->steps( [
            'getUser',                 'setSessionInfo',
            $self->p->groupsAndMacros, 'setLocalGroups'
        ]
    );
    $req->data->{findUserChoice} = '1_LDAP';
    $self->logger->debug("$prefix API call");
    my $res = $self->p->process($req);
    if ($res) {
        my $txt = portalConsts->{$res};
        $self->userLogger->error("API call: unable to resolve user: $txt");
        return $self->p->sendJSONresponse( $req,
            { error => ( $txt || $res ) }, 400 );
    }
    $req->userData( $req->sessionInfo );
    return $self->p->sendError( $req, 'User without mail', 400 )
      unless $req->userData->{mail};
    $req->data->{skipMaxAccounts} = 1;
    return $self->$sub( $req, 1 );
}

sub missingToken {
    my ( $self, $req ) = @_;
    return $self->p->sendError( $req, 'Tokens not allowed', 403 )
      unless $self->validTokens;
    my $authorization = $req->{env}->{HTTP_AUTHORIZATION};
    return $self->p->sendError( $req, 'Bad token', 403 )
      unless $authorization =~ $self->validTokens;
    return;
}

1;
