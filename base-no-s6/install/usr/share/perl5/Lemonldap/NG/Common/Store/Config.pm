package Lemonldap::NG::Common::Store::Config;

use strict;
use warnings;
use Config::IniFiles;
use Lemonldap::NG::Common::Conf::Constants qw(DEFAULTCONFFILE DEFAULTSECTION);

our $VERSION = '2.23.0';

# Default values for [store] section
# Placeholders __CONFDIR__, __DATADIR__, __CACHEDIR__ are replaced at install
# time by the Makefile with actual installation paths.
my %DEFAULTS = (
    managerOverridesDir => '/etc/lemonldap-ng/manager-overrides.d',
    stateFile           => '/var/lib/lemonldap-ng/plugins-state.json',
    gpgVerify           => 'optional',
    httpTimeout         => 30,
    cacheDir            => '/var/lib/lemonldap-ng/store',
);

sub new {
    my ( $class, %args ) = @_;
    my $self = bless { confFile => $args{confFile} }, $class;
    $self->_load();
    return $self;
}

# Read the [store] section from lemonldap-ng.ini
sub _load {
    my ($self) = @_;
    my $file =
         $self->{confFile}
      || $ENV{LLNG_DEFAULTCONFFILE}
      || DEFAULTCONFFILE;
    $self->{confFile} = $file;

    # Start with defaults
    my %conf = %DEFAULTS;

    if ( -r $file ) {
        my $cfg = Config::IniFiles->new(
            -file          => $file,
            -allowcontinue => 1,
        );
        if ($cfg) {

            # Load [all] defaults first
            if ( $cfg->SectionExists(DEFAULTSECTION) ) {
                foreach ( $cfg->Parameters(DEFAULTSECTION) ) {
                    $conf{$_} = $cfg->val( DEFAULTSECTION, $_ );
                }
            }

            # Then overlay [store] section
            if ( $cfg->SectionExists('store') ) {
                foreach ( $cfg->Parameters('store') ) {
                    $conf{$_} = $cfg->val( 'store', $_ );
                }
            }
        }
    }

    # Environment variables override (highest priority)
    $conf{storeUrls}           = $ENV{LLNG_STORE_URLS} if $ENV{LLNG_STORE_URLS};
    $conf{managerOverridesDir} = $ENV{LLNG_STORE_OVERRIDESDIR}
      if $ENV{LLNG_STORE_OVERRIDESDIR};
    $conf{stateFile} = $ENV{LLNG_STORE_STATEFILE} if $ENV{LLNG_STORE_STATEFILE};
    $conf{cacheDir}  = $ENV{LLNG_STORE_CACHEDIR}  if $ENV{LLNG_STORE_CACHEDIR};
    $conf{gpgVerify} = $ENV{LLNG_STORE_GPGVERIFY} if $ENV{LLNG_STORE_GPGVERIFY};
    $conf{gpgKeyring} = $ENV{LLNG_STORE_GPGKEYRING}
      if $ENV{LLNG_STORE_GPGKEYRING};

    # Parse storeUrls into array
    if ( $conf{storeUrls} ) {
        $conf{_storeUrls} =
          [ map { s/^\s+|\s+$//gr } split /,/, $conf{storeUrls} ];
    }
    else {
        $conf{_storeUrls} = [];
    }

    $self->{conf} = \%conf;
}

# Accessors
sub storeUrls           { return @{ $_[0]->{conf}{_storeUrls} } }
sub managerOverridesDir { return $_[0]->{conf}{managerOverridesDir} }
sub stateFile           { return $_[0]->{conf}{stateFile} }
sub gpgVerify           { return $_[0]->{conf}{gpgVerify} }
sub gpgKeyring          { return $_[0]->{conf}{gpgKeyring} }
sub httpTimeout         { return $_[0]->{conf}{httpTimeout} }
sub cacheDir            { return $_[0]->{conf}{cacheDir} }
sub confFile            { return $_[0]->{confFile} }

# Override a config value (used by CLI options)
sub override {
    my ( $self, $key, $value ) = @_;
    $self->{conf}{$key} = $value;
}

sub get { return $_[0]->{conf}{ $_[1] } }

# Add a store URL to lemonldap-ng.ini
# Creates [store] section if it doesn't exist
sub addStore {
    my ( $self, $url ) = @_;
    my $file = $self->{confFile};

    # Check for duplicates
    my @current = $self->storeUrls;
    for my $existing (@current) {
        if ( $existing eq $url ) {
            return ( 0, "Store URL already configured: $url" );
        }
    }

    my $cfg;
    if ( -e $file ) {
        $cfg = Config::IniFiles->new(
            -file          => $file,
            -allowcontinue => 1,
        );
        return ( 0,
            "Cannot parse $file: " . join( "\n", @Config::IniFiles::errors ) )
          unless $cfg;
    }
    else {
        return ( 0, "Configuration file not found: $file" );
    }

    # Create [store] section if needed
    unless ( $cfg->SectionExists('store') ) {
        $cfg->AddSection('store');
    }

    # Update storeUrls
    push @current, $url;
    my $new_value = join ', ', @current;

    if ( $cfg->exists( 'store', 'storeUrls' ) ) {
        $cfg->setval( 'store', 'storeUrls', $new_value );
    }
    else {
        $cfg->newval( 'store', 'storeUrls', $new_value );
    }

    $cfg->RewriteConfig();
    $self->_load();    # Reload
    return ( 1, "Store added: $url" );
}

# Remove a store URL from lemonldap-ng.ini
sub removeStore {
    my ( $self, $url ) = @_;
    my $file = $self->{confFile};

    my @current = $self->storeUrls;
    my @new     = grep { $_ ne $url } @current;

    if ( scalar @new == scalar @current ) {
        return ( 0, "Store URL not found: $url" );
    }

    my $cfg = Config::IniFiles->new(
        -file          => $file,
        -allowcontinue => 1,
    );
    return ( 0, "Cannot parse $file" ) unless $cfg;

    if (@new) {
        $cfg->setval( 'store', 'storeUrls', join( ', ', @new ) );
    }
    else {
        $cfg->delval( 'store', 'storeUrls' );
    }

    $cfg->RewriteConfig();
    $self->_load();    # Reload
    return ( 1, "Store removed: $url" );
}

1;
