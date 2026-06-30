# Copyright: Linagora <https://linagora.com>
# Author   : Xavier Guimard
# License  : GPL-2+
package Lemonldap::NG::Portal::Plugins::MailAutodiscover;

use strict;
use Mouse;

extends 'Lemonldap::NG::Portal::Main::Plugin';

# Default mail servers, overridden by the mailAutodiscover* custom plugin
# parameters in the LLNG configuration (see README).
our $imapServer = 'imap.example.com';
our $smtpServer = 'smtp.example.com';
our $imapPort   = 993;
our $smtpPort   = 465;

my $autodiscover = <<'EOF';
<?xml version="1.0" encoding="utf-8" ?>
<Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006">
 <Response xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a">
  <Account>
   <AccountType>email</AccountType>
   <Action>settings</Action>
   <Protocol>
    <Type>IMAP</Type>
    <Server>%IMAPSERVER%</Server>
    <Port>%IMAPPORT%</Port>
    <DomainRequired>off</DomainRequired>
    <LoginName>%EMAILADDRESS%</LoginName>
    <SPA>off</SPA>
    <SSL>on</SSL>
    <AuthRequired>on</AuthRequired>
   </Protocol>
   <Protocol>
    <Type>SMTP</Type>
    <Server>%SMTPSERVER%</Server>
    <Port>%SMTPPORT%</Port>
    <DomainRequired>off</DomainRequired>
    <LoginName>%EMAILADDRESS%</LoginName>
    <SPA>off</SPA>
    <Encryption>SSL</Encryption>
    <AuthRequired>on</AuthRequired>
    <UsePOPAuth>off</UsePOPAuth>
    <SMTPLast>off</SMTPLast>
   </Protocol>
  </Account>
 </Response>
</Autodiscover>
EOF

my $validEmail =
qr#^(?:(?^u:(?:(?^u:(?>(?^u:(?^u:(?>(?^u:(?>(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|\.|\s*"(?^u:(?^u:[^\\"])|(?^u:\\(?^u:[^\x0A\x0D])))+"\s*))+))|(?>(?^u:(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*"(?^u:(?^u:[^\\"])|(?^u:\\(?^u:[^\x0A\x0D])))*"(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*)))+))?)(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*<(?^u:(?^u:(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*(?^u:(?>[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?:\.[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+)*))(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*"(?^u:(?^u:[^\\"])|(?^u:\\(?^u:[^\x0A\x0D])))*"(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*)))\@(?^u:(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*(?^u:(?>[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?:\.[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+)*))(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*\[(?:\s*(?^u:(?^u:[^\[\]\\])|(?^u:\\(?^u:[^\x0A\x0D]))))*\s*\](?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))))>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*)))|(?^u:(?^u:(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*(?^u:(?>[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?:\.[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+)*))(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*"(?^u:(?^u:[^\\"])|(?^u:\\(?^u:[^\x0A\x0D])))*"(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*)))\@(?^u:(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*(?^u:(?>[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?:\.[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+)*))(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*\[(?:\s*(?^u:(?^u:[^\[\]\\])|(?^u:\\(?^u:[^\x0A\x0D]))))*\s*\](?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*)))))(?>(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))*)))$#o;

has imapServer => ( is => 'rw' );
has smtpServer => ( is => 'rw' );
has imapPort   => ( is => 'rw' );
has smtpPort   => ( is => 'rw' );

sub init {
    my ($self) = @_;

    # Resolve mail servers with the following precedence:
    #   1. environment variable (LLNG_MAILAUTODISCOVER_*)
    #   2. LLNG custom parameter (mailAutodiscover*)
    #   3. package default
    $self->imapServer( $ENV{LLNG_MAILAUTODISCOVER_IMAP_SERVER}
          || $self->conf->{mailAutodiscoverImapServer}
          || $imapServer );
    $self->smtpServer( $ENV{LLNG_MAILAUTODISCOVER_SMTP_SERVER}
          || $self->conf->{mailAutodiscoverSmtpServer}
          || $smtpServer );
    $self->imapPort( $ENV{LLNG_MAILAUTODISCOVER_IMAP_PORT}
          || $self->conf->{mailAutodiscoverImapPort}
          || $imapPort );
    $self->smtpPort( $ENV{LLNG_MAILAUTODISCOVER_SMTP_PORT}
          || $self->conf->{mailAutodiscoverSmtpPort}
          || $smtpPort );

    $self->addUnauthRoute(
        autodiscover => {
            'autodiscover.json' => 'autodiscoverJson',
            'autodiscover.xml'  => 'autodiscover',
        },
        [ 'GET', 'POST' ]
    )->addUnauthRoute(
        EWS => 'notFound',
        [ 'GET', 'POST' ]
    )->addAuthRoute(
        autodiscover => {
            'autodiscover.json' => 'autodiscoverJson',
            'autodiscover.xml'  => 'autodiscover',
        },
        [ 'GET', 'POST' ]
    );
}

sub autodiscover {
    my ( $self, $req ) = @_;
    my $data = $autodiscover;
    my $mail = $req->param('email');
    $mail = '%EMAILADDRESS%' unless $mail and $mail =~ $validEmail;
    $data =~ s/%IMAPSERVER%/$self->imapServer/sge;
    $data =~ s/%SMTPSERVER%/$self->smtpServer/sge;
    $data =~ s/%IMAPPORT%/$self->imapPort/sge;
    $data =~ s/%SMTPPORT%/$self->smtpPort/sge;
    $data =~ s/%EMAILADDRESS%/$mail/sg;

    return [
        200,
        [
            'Content-Type'   => 'application/xml',
            'Content-Length' => length($data)
        ],
        [$data]
    ];
}

sub autodiscoverJson {
    my ( $self, $req, $version, $email ) = @_;

    if ( $version && $version eq 'v1.0' && $email && $email =~ $validEmail ) {
        my $protocol = $req->param('Protocol') // '';

        # Handle AutodiscoverV1 protocol - redirect to XML autodiscover
        if ( $protocol =~ /^AutodiscoverV1$/i ) {
            my $url  = $req->portal . '/autodiscover/autodiscover.xml';
            my $json = qq({"Protocol":"AutodiscoverV1","Url":"$url"});
            return [
                200,
                [
                    'Content-Type'   => 'application/json',
                    'Content-Length' => length($json)
                ],
                [$json]
            ];
        }
    }

    return [
        404,
        [ 'Content-Type' => 'text/html' ],
        ['<html><body>Not found...</body></html>']
    ];
}

sub notFound {
    return [
        404,
        [ 'Content-Type' => 'text/html' ],
        ['<html><body>Not found...</body></html>']
    ];
}

1;
