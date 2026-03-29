package Lemonldap::NG::Common::Store;

use strict;
use warnings;
use Getopt::Long   qw(:config pass_through);
use File::Temp     qw(tempdir tempfile);
use File::Basename qw(dirname);

use Lemonldap::NG::Common::Store::Config;
use Lemonldap::NG::Common::Store::Remote;
use Lemonldap::NG::Common::Store::Verify;
use Lemonldap::NG::Common::Store::Install;
use Lemonldap::NG::Common::Store::State;

our $VERSION = '2.23.0';

my %COMMANDS = (
    'add-store'    => \&cmd_addStore,
    'remove-store' => \&cmd_removeStore,
    'list'         => \&cmd_list,
    'info'         => \&cmd_info,
    'install'      => \&cmd_install,
    'remove'       => \&cmd_remove,
    'installed'    => \&cmd_installed,
    'update'       => \&cmd_update,
    'check'        => \&cmd_check,
    'verify'       => \&cmd_verify,
    'rebuild'      => \&cmd_rebuild,
);

sub run {
    my ( $class, @args ) = @_;

    my (
        $store_url,  $search,          $tag,      $version,
        $force,      $allow_overwrite, $activate, $help,
        $state_file, $cache_dir,       $plugins_dir
    );
    local @ARGV = @args;

    GetOptions(
        'store=s'         => \$store_url,
        'search=s'        => \$search,
        'tag=s'           => \$tag,
        'version=s'       => \$version,
        'force'           => \$force,
        'allow-overwrite' => \$allow_overwrite,
        'activate'        => \$activate,
        'state-file=s'    => \$state_file,
        'cache-dir=s'     => \$cache_dir,
        'plugins-dir=s'   => \$plugins_dir,
        'help|h'          => \$help,
    ) or _usage(1);

    my $command = shift @ARGV;
    _usage(0) if $help && !$command;
    _usage(1) unless $command;

    my $cmd_info = $COMMANDS{$command};
    unless ($cmd_info) {
        print STDERR "Unknown command: $command\n";
        _usage(1);
    }

    # Initialize components
    my $config = Lemonldap::NG::Common::Store::Config->new();

    # CLI overrides (highest priority)
    $config->override( 'stateFile',           $state_file )  if $state_file;
    $config->override( 'cacheDir',            $cache_dir )   if $cache_dir;
    $config->override( 'managerOverridesDir', $plugins_dir ) if $plugins_dir;
    my $opts = {
        config          => $config,
        store_url       => $store_url,
        search          => $search,
        tag             => $tag,
        version         => $version,
        force           => $force,
        allow_overwrite => $allow_overwrite,
        activate        => $activate,
        args            => \@ARGV,
    };

    $cmd_info->($opts);
}

sub cmd_addStore {
    my ($opts) = @_;
    my $url = $opts->{args}[0]
      or die "Usage: lemonldap-ng-store add-store URL\n";

    # Warn about HTTP
    if ( $url =~ m|^http://|i ) {
        print "WARNING: Using HTTP (not HTTPS) is insecure.\n";
        unless ( $opts->{force} ) {
            print "Use --force to add anyway.\n";
            exit 1;
        }
    }

    my ( $ok, $msg ) = $opts->{config}->addStore($url);
    unless ($ok) {
        die "Error: $msg\n";
    }
    print "$msg\n";

    # Fetch index to get GPG key URL
    my $config = $opts->{config};
    my $remote = Lemonldap::NG::Common::Store::Remote->new(
        timeout  => $config->httpTimeout,
        cacheDir => $config->cacheDir,
    );

    my ( $idx_ok, $data ) = $remote->fetchIndex($url);
    if ( $idx_ok && $data->{store}{gpgKey} ) {
        my $gpg_url = $data->{store}{gpgKey};
        print "Importing GPG key from $gpg_url...\n";

        # Download key to temp file
        my $tmpfile  = File::Temp->new( SUFFIX => '.asc' );
        my $tmp_path = $tmpfile->filename;
        my ( $dl_ok, $dl_err ) = $remote->downloadFile( $gpg_url, $tmp_path );
        if ($dl_ok) {

            # Import the key and capture fingerprint from import output
            my $import_out = `gpg --batch --import '$tmp_path' 2>&1`;
            my $import_ok  = $? == 0;

            # Extract fingerprint: try gpg --with-colons on the file
            my $fp_output =
                 `gpg --with-colons --show-keys '$tmp_path' 2>/dev/null`
              || `gpg --with-colons --import-options show-only --import '$tmp_path' 2>/dev/null`
              || '';
            my ($fingerprint) = $fp_output =~ /^fpr:+([A-F0-9]+)/m;

            # Fallback: extract from import output
            if ( !$fingerprint && $import_out =~ /([A-F0-9]{40})/i ) {
                $fingerprint = $1;
            }

            if ( $import_ok && $fingerprint ) {
                print "  Imported key: $fingerprint\n";

                # Store fingerprint associated with this store URL
                my $state = Lemonldap::NG::Common::Store::State->new(
                    stateFile => $config->stateFile, );
                $state->addStore( $url, gpgFingerprint => $fingerprint );
                print "  GPG fingerprint saved for this store\n";
            }
            elsif ($import_ok) {
                print
                  "  Warning: key imported but could not extract fingerprint\n";
            }
            else {
                print "  Warning: GPG import failed: $import_out\n";
            }
        }
        else {
            print "  Warning: could not download GPG key: $dl_err\n";
        }
    }
    elsif ($idx_ok) {
        print "Note: this store does not publish a GPG key\n";
    }
    else {
        print "Warning: could not fetch store index: $data\n";
    }
}

sub cmd_removeStore {
    my ($opts) = @_;
    my $url = $opts->{args}[0]
      or die "Usage: lemonldap-ng-store remove-store URL\n";

    my ( $ok, $msg ) = $opts->{config}->removeStore($url);
    unless ($ok) {
        die "Error: $msg\n";
    }
    print "$msg\n";

    # Remove stored fingerprint
    my $state = Lemonldap::NG::Common::Store::State->new(
        stateFile => $opts->{config}->stateFile, );
    $state->removeStore($url);
}

sub cmd_list {
    my ($opts) = @_;
    my $config = $opts->{config};

    my @stores =
      $opts->{store_url}
      ? ( $opts->{store_url} )
      : $config->storeUrls;

    unless (@stores) {
        die
"No stores configured. Use 'lemonldap-ng-store add-store URL' first.\n";
    }

    my $remote = Lemonldap::NG::Common::Store::Remote->new(
        timeout  => $config->httpTimeout,
        cacheDir => $config->cacheDir,
    );

    my $llng_version = _getLlngVersion();

    printf "%-25s %-10s %-8s %s\n", 'NAME', 'VERSION', 'COMPAT', 'SUMMARY';
    printf "%s\n", '-' x 78;

    for my $store_url (@stores) {
        my ( $ok, $data ) = $remote->fetchIndexCached($store_url);
        unless ($ok) {
            print STDERR "Warning: $data\n";
            next;
        }

        my @plugins = @{ $data->{plugins} || [] };

        # Apply search filter
        if ( $opts->{search} ) {
            my $term = lc( $opts->{search} );
            @plugins = grep {
                     $_->{name}                  =~ /\Q$term\E/i
                  || $_->{summary}               =~ /\Q$term\E/i
                  || ( $_->{description} || '' ) =~ /\Q$term\E/i
            } @plugins;
        }

        # Apply tag filter
        if ( $opts->{tag} ) {
            my $tag = lc( $opts->{tag} );
            @plugins = grep {
                my @tags = map { lc } @{ $_->{tags} || [] };
                grep { $_ eq $tag } @tags;
            } @plugins;
        }

        for my $plugin (@plugins) {
            my $compat = _checkCompat( $plugin->{llng_compat}, $llng_version );
            next if !$compat && !$opts->{force};
            my $compat_str = $compat ? 'OK' : 'INCOMPAT';
            printf "%-25s %-10s %-8s %s\n",
              $plugin->{name},
              $plugin->{version},
              $compat_str,
              $plugin->{summary} || '';
        }
    }
}

sub cmd_info {
    my ($opts) = @_;
    my $name = $opts->{args}[0]
      or die "Usage: lemonldap-ng-store info PLUGIN_NAME\n";

    my $plugin = _findPlugin( $opts, $name );
    die "Plugin not found: $name\n" unless $plugin;

    my $llng_version = _getLlngVersion();
    my $compat       = _checkCompat( $plugin->{llng_compat}, $llng_version );

    print join(
        "\n",
        map {
            my $k = lc($_);
            my $n = $_;
            $n =~ s/_/ /g;
            my $v = $plugin->{$k} // '';
            $v = ref($v) ? join( ', ', @$v ) : $v;
            sprintf "%-14s: %s", $n, $v // ''
          } qw(Name Version Summary Description Author License LLNG_compat
          Compatible Tags Homepage Published SHA256)
    ) . "\n";

    if ( $plugin->{perl_requires} && %{ $plugin->{perl_requires} } ) {
        print "Perl requires :\n";
        for my $mod ( sort keys %{ $plugin->{perl_requires} } ) {
            my $ver     = $plugin->{perl_requires}{$mod};
            my $present = _checkPerlModule( $mod, $ver );
            printf "  %-30s %-10s %s\n", $mod,
              ( $ver || 'any' ),
              ( $present ? 'installed' : 'MISSING' );
        }
    }

    # Check if locally installed
    my $state = Lemonldap::NG::Common::Store::State->new(
        stateFile => $opts->{config}->stateFile, );
    my $installed = $state->get($name);
    printf "%-14s: %s\n", 'Installed',
      ( $installed ? "Yes (version $installed->{version})" : 'No' );
}

sub cmd_install {
    my ($opts) = @_;
    my @names = @{ $opts->{args} };
    die "Usage: lemonldap-ng-store install PLUGIN_NAME [PLUGIN_NAME...]\n"
      unless @names;

    my $config    = $opts->{config};
    my $installer = Lemonldap::NG::Common::Store::Install->new(
        managerOverridesDir => $config->managerOverridesDir,
        allowOverwrite      => $opts->{allow_overwrite},
    );
    my $state =
      Lemonldap::NG::Common::Store::State->new( stateFile => $config->stateFile,
      );

    my $errors = 0;
    for my $name (@names) {
        print "\n" if $errors || $name ne $names[0];
        eval { _installOne( $opts, $name, $config, $installer, $state ); };
        if ($@) {
            print STDERR $@;
            $errors++;
            next;
        }
    }

    # Rebuild manager once after all installs
    if ( @names > $errors ) {
        print "\nRebuilding manager files...\n";
        my ( $ok, $rebuild_msg ) = $installer->rebuildManager();
        print "  $rebuild_msg\n";
        print "\nDon't forget to restart the portal service.\n";
    }

    exit(1) if $errors;
}

sub _installOne {
    my ( $opts, $name, $config, $installer, $state ) = @_;

    # 1. Find plugin in stores
    my $plugin = _findPlugin( $opts, $name, $opts->{version} );
    die "Plugin not found: $name\n" unless $plugin;

    my $store_url = $plugin->{_store_url};

    print "Installing $plugin->{name} version $plugin->{version}...\n";

    # 2. Check LLNG version compatibility
    my $llng_version = _getLlngVersion();
    if ( $plugin->{llng_compat}
        && !_checkCompat( $plugin->{llng_compat}, $llng_version ) )
    {
        if ( $opts->{force} ) {
            print "WARNING: Plugin requires $plugin->{llng_compat} "
              . "(current: $llng_version), installing anyway (--force)\n";
        }
        else {
            die "Error: Plugin requires LLNG $plugin->{llng_compat} "
              . "(current: $llng_version). Use --force to override.\n";
        }
    }

    # 3. Check Perl dependencies
    if ( $plugin->{perl_requires} ) {
        my @missing;
        for my $mod ( sort keys %{ $plugin->{perl_requires} } ) {
            my $ver = $plugin->{perl_requires}{$mod};
            unless ( _checkPerlModule( $mod, $ver ) ) {
                push @missing, $ver ? "$mod >= $ver" : $mod;
            }
        }
        if (@missing) {
            print "WARNING: Missing Perl dependencies:\n";
            for my $m (@missing) {
                ( my $deb = $m ) =~ s/ .*//;
                $deb =~ s/::/-/g;
                $deb = 'lib' . lc($deb) . '-perl';
                print "  $m  (apt install $deb or cpan install)\n";
            }
            print
"  Plugin will be installed but may not work until dependencies are met.\n";
        }
    }

    # 4. Download archive
    $store_url =~ s|/+$||;
    my $archive_url = "$store_url/$plugin->{archive}";

    my $tmpdir       = tempdir( CLEANUP => 1 );
    my $archive_file = "$tmpdir/$plugin->{archive}";

    my $remote = Lemonldap::NG::Common::Store::Remote->new(
        timeout  => $config->httpTimeout,
        cacheDir => $config->cacheDir,
    );

    print "  Downloading $plugin->{archive}...\n";
    my ( $ok, $err ) = $remote->downloadFile( $archive_url, $archive_file );
    die "Error: $err\n" unless $ok;

    # 5. Verify SHA256
    # Get trusted fingerprint for this store (TOFU from add-store)
    my $store_info = $state->getStore($store_url);
    my @fingerprints =
      $store_info && $store_info->{gpgFingerprint}
      ? ( $store_info->{gpgFingerprint} )
      : ();

    my $verify = Lemonldap::NG::Common::Store::Verify->new(
        gpgVerify       => $config->gpgVerify,
        gpgKeyring      => $config->gpgKeyring,
        gpgFingerprints => \@fingerprints,
    );

    print "  Verifying SHA256...\n";
    ( $ok, $err ) = $verify->verifySha256( $archive_file, $plugin->{sha256} );
    die "Error: $err\n" unless $ok;

    # 6. Verify GPG
    if ( $config->gpgVerify ne 'disabled' ) {
        my $sig_file;
        if ( $plugin->{signature} ) {
            my $sig_url = "$store_url/$plugin->{signature}";
            $sig_file = "$tmpdir/$plugin->{signature}";
            print "  Downloading GPG signature...\n";
            my ( $sig_ok, $sig_err ) =
              $remote->downloadFile( $sig_url, $sig_file );
            unless ($sig_ok) {
                $sig_file = undef;
                print "  Warning: Could not download signature: $sig_err\n";
            }
        }

        print "  Verifying GPG signature...\n";
        ( $ok, my $gpg_msg ) = $verify->verifyGpg( $archive_file, $sig_file );
        print "  $gpg_msg\n" if $gpg_msg;
        die "Error: GPG verification failed\n" unless $ok;
    }

    # 7. Extract and validate
    print "  Extracting and validating...\n";
    my ( $ext_ok, $meta, $plugin_dir ) =
      $installer->extractAndValidate($archive_file);
    die "Error: $meta\n" unless $ext_ok;

    # 8. Check if already installed (upgrade)
    my $existing = $state->get($name);
    if ($existing) {
        print "  Upgrading from version $existing->{version}...\n";
        $installer->removeFiles( $existing->{files} );
        $state->remove($name);
    }

    # 9. Install files
    print "  Installing files...\n";
    ( $ok, my $files_or_err ) = $installer->installFiles( $plugin_dir, $meta );
    unless ($ok) {
        die "Error: $files_or_err\n";
    }

    # 10. Update state
    $state->add(
        $name,
        version        => $meta->{version},
        installed_from => $store_url,
        archive_sha256 => $plugin->{sha256},
        files          => $files_or_err,
    );

    print "  Installed " . scalar(@$files_or_err) . " file(s)\n";

    # 11. Activate plugin if --activate and customPlugins declared
    if ( $opts->{activate} && $meta->{customPlugins} ) {
        print "  Activating plugin...\n";
        my ( $act_ok, $act_msg ) =
          _activateCustomPlugins( $meta->{customPlugins} );
        print "  $act_msg\n";
    }

    # 12. Post-install instructions
    if ( $meta->{customPlugins} && !$opts->{activate} ) {
        print
"  Note: add to customPlugins in LLNG configuration: $meta->{customPlugins}\n";
    }
    if ( $meta->{post_install} ) {
        print "  Note from plugin author: $meta->{post_install}\n";
    }
}

sub cmd_remove {
    my ($opts) = @_;
    my @names = @{ $opts->{args} };
    die "Usage: lemonldap-ng-store remove PLUGIN_NAME [PLUGIN_NAME...]\n"
      unless @names;

    my $config = $opts->{config};

    my $state =
      Lemonldap::NG::Common::Store::State->new( stateFile => $config->stateFile,
      );
    my $installer = Lemonldap::NG::Common::Store::Install->new(
        managerOverridesDir => $config->managerOverridesDir, );

    my $errors  = 0;
    my $removed = 0;
    for my $name (@names) {
        my $installed = $state->get($name);
        unless ($installed) {
            print STDERR "Plugin not installed: $name\n";
            $errors++;
            next;
        }

        print "Removing $name (version $installed->{version})...\n";
        $installer->removeFiles( $installed->{files} );
        $state->remove($name);
        $removed++;
    }

    # Rebuild manager once after all removals
    if ($removed) {
        print "\nRebuilding manager files...\n";
        my ( $ok, $msg ) = $installer->rebuildManager();
        print "  $msg\n\nDon't forget to:
  1. Remove the plugin module(s) from customPlugins in LLNG configuration
  2. Restart the portal service\n";
    }

    exit(1) if $errors;
}

sub cmd_installed {
    my ($opts) = @_;
    my $state = Lemonldap::NG::Common::Store::State->new(
        stateFile => $opts->{config}->stateFile, );

    my %installed = $state->installed;
    unless (%installed) {
        print "No plugins installed.\n";
        return;
    }

    printf "%-25s %-10s %-20s %s\n", 'NAME', 'VERSION', 'INSTALLED', 'FROM';
    printf "%s\n", '-' x 78;

    for my $name ( sort keys %installed ) {
        my $info = $installed{$name};
        printf "%-25s %-10s %-20s %s\n",
          $name,
          $info->{version},
          $info->{installed_date} || '',
          $info->{installed_from} || '';
    }
}

sub cmd_update {
    my ($opts) = @_;
    my $config = $opts->{config};

    my @stores =
      $opts->{store_url}
      ? ( $opts->{store_url} )
      : $config->storeUrls;

    unless (@stores) {
        die "No stores configured.\n";
    }

    my $remote = Lemonldap::NG::Common::Store::Remote->new(
        timeout  => $config->httpTimeout,
        cacheDir => $config->cacheDir,
    );

    for my $store_url (@stores) {
        print "Updating index from $store_url...\n";
        my ( $ok, $data ) =
          $remote->fetchIndexCached( $store_url, 1 );    # force refresh
        if ($ok) {
            my $count = scalar @{ $data->{plugins} || [] };
            print "  $count plugin(s) available\n";
        }
        else {
            print STDERR "  Error: $data\n";
        }
    }
}

sub cmd_check {
    my ($opts) = @_;
    my $config = $opts->{config};
    my $name   = $opts->{args}[0];

    my $state =
      Lemonldap::NG::Common::Store::State->new( stateFile => $config->stateFile,
      );

    my %installed = $state->installed;
    unless (%installed) {
        print "No plugins installed.\n";
        return;
    }

    # If a specific plugin name is given, check only that one
    if ($name) {
        unless ( $installed{$name} ) {
            die "Plugin not installed: $name\n";
        }
        %installed = ( $name => $installed{$name} );
    }

    my @stores = $config->storeUrls;
    unless (@stores) {
        die "No stores configured.\n";
    }

    my $remote = Lemonldap::NG::Common::Store::Remote->new(
        timeout  => $config->httpTimeout,
        cacheDir => $config->cacheDir,
    );

    # Build remote plugin catalog
    my %remote_plugins;
    for my $store_url (@stores) {
        my ( $ok, $data ) = $remote->fetchIndexCached($store_url);
        next unless $ok;
        for my $p ( @{ $data->{plugins} || [] } ) {
            $remote_plugins{ $p->{name} } = $p
              unless $remote_plugins{ $p->{name} }
              && _versionCmp( $remote_plugins{ $p->{name} }{version},
                $p->{version} ) >= 0;
        }
    }

    my $updates = 0;
    for my $pname ( sort keys %installed ) {
        my $local  = $installed{$pname};
        my $remote = $remote_plugins{$pname};
        if ( $remote
            && _versionCmp( $remote->{version}, $local->{version} ) > 0 )
        {
            printf "%-25s %s -> %s\n", $pname, $local->{version},
              $remote->{version};
            $updates++;
        }
    }

    if ( $updates == 0 ) {
        print "All installed plugins are up to date.\n";
    }
    else {
        print "\n$updates update(s) available.\n";
    }
}

sub cmd_verify {
    my ($opts) = @_;
    my $file = $opts->{args}[0]
      or die "Usage: lemonldap-ng-store verify ARCHIVE_FILE\n";

    unless ( -r $file ) {
        die "Cannot read file: $file\n";
    }

    my $config = $opts->{config};

    # Extract and validate structure
    my $installer = Lemonldap::NG::Common::Store::Install->new(
        managerOverridesDir => $config->managerOverridesDir, );

    print "Validating archive structure...\n";
    my ( $ok, $meta, $plugin_dir ) = $installer->extractAndValidate($file);
    if ($ok) {
        print "  Structure: OK
  Name:      $meta->{name}
  Version:   $meta->{version}\n";
    }
    else {
        print "  Structure: FAILED - $meta\n";
        exit 1;
    }

    # GPG verification (if .asc file exists alongside)
    my $sig_file = "${file}.asc";
    if ( -r $sig_file ) {
        my $verify = Lemonldap::NG::Common::Store::Verify->new(
            gpgVerify  => $config->gpgVerify,
            gpgKeyring => $config->gpgKeyring,
        );
        ( $ok, my $gpg_msg ) = $verify->verifyGpg( $file, $sig_file );
        print "  GPG:       $gpg_msg\n";
    }
    else {
        print "  GPG:       No .asc signature file found\n";
    }

    print "Archive valid.\n";
}

sub cmd_rebuild {
    my ($opts) = @_;
    my $config = $opts->{config};

    my $installer = Lemonldap::NG::Common::Store::Install->new(
        managerOverridesDir => $config->managerOverridesDir, );

    print "Rebuilding manager files...\n";
    my ( $ok, $msg ) = $installer->rebuildManager();
    print "  $msg\n";
    unless ($ok) {
        die "Error: rebuild failed\n";
    }
}

#
# Helper functions
#

sub _findPlugin {
    my ( $opts, $name, $wanted_version ) = @_;
    my $config = $opts->{config};

    my @stores =
      $opts->{store_url}
      ? ( $opts->{store_url} )
      : $config->storeUrls;

    my $remote = Lemonldap::NG::Common::Store::Remote->new(
        timeout  => $config->httpTimeout,
        cacheDir => $config->cacheDir,
    );

    my $best;
    for my $store_url (@stores) {
        my ( $ok, $data ) = $remote->fetchIndexCached($store_url);
        next unless $ok;

        for my $p ( @{ $data->{plugins} || [] } ) {
            next unless $p->{name} eq $name;
            if ($wanted_version) {
                next unless $p->{version} eq $wanted_version;
            }
            if ( !$best || _versionCmp( $p->{version}, $best->{version} ) > 0 )
            {
                $best = { %$p, _store_url => $store_url };
            }
        }
    }

    return $best;
}

sub _getLlngVersion {
    eval { require Lemonldap::NG::Common };
    return $Lemonldap::NG::Common::VERSION || '0';
}

# Simple version comparison (X.Y.Z format)
sub _versionCmp {
    my ( $a, $b ) = @_;
    my @a = split /\./, ( $a || '0' );
    my @b = split /\./, ( $b || '0' );
    for my $i ( 0 .. 3 ) {
        my $cmp = ( $a[$i] || 0 ) <=> ( $b[$i] || 0 );
        return $cmp if $cmp;
    }
    return 0;
}

# Check version compatibility string like ">=2.20.0" or ">=2.20.0,<3.0.0"
sub _checkCompat {
    my ( $compat_str, $current ) = @_;
    return 1 unless $compat_str;
    return 1 unless $current;

    for my $constraint ( split /\s*,\s*/, $compat_str ) {
        if ( $constraint =~ /^>=\s*(.+)/ ) {
            return 0 if _versionCmp( $current, $1 ) < 0;
        }
        elsif ( $constraint =~ /^>\s*(.+)/ ) {
            return 0 if _versionCmp( $current, $1 ) <= 0;
        }
        elsif ( $constraint =~ /^<=\s*(.+)/ ) {
            return 0 if _versionCmp( $current, $1 ) > 0;
        }
        elsif ( $constraint =~ /^<\s*(.+)/ ) {
            return 0 if _versionCmp( $current, $1 ) >= 0;
        }
        elsif ( $constraint =~ /^==?\s*(.+)/ ) {
            return 0 if _versionCmp( $current, $1 ) != 0;
        }
    }
    return 1;
}

sub _activateCustomPlugins {
    my ($modules) = @_;

    # Find lemonldap-ng-cli
    my $cli;
    for my $dir ( split /:/, $ENV{PATH} || '' ) {
        my $path = "$dir/lemonldap-ng-cli";
        if ( -x $path ) { $cli = $path; last }
    }
    unless ($cli) {
        return ( 0,
            'lemonldap-ng-cli not found, cannot activate automatically' );
    }

    # Read current customPlugins value
    my $current = `$cli --json 1 get customPlugins 2>/dev/null`;
    chomp $current;

    # Parse: cli outputs JSON, could be "value" or null
    $current =~ s/^"(.*)"$/$1/s;
    $current = '' if $current eq 'null' || $current eq '""';

    # Build new value: add each module if not already present
    my @existing = $current ? split( /\s*,\s*/, $current ) : ();
    my @to_add   = split /\s*,\s*/, $modules;
    my $changed  = 0;

    for my $mod (@to_add) {
        $mod =~ s/^\s+|\s+$//g;
        unless ( grep { $_ eq $mod } @existing ) {
            push @existing, $mod;
            $changed = 1;
        }
    }

    unless ($changed) {
        return ( 1, 'Plugin already in customPlugins' );
    }

    my $new_value = join( ', ', @existing );
    my $output    = `$cli --yes 1 set customPlugins '$new_value' 2>&1`;
    my $exit      = $? >> 8;

    if ( $exit != 0 ) {
        return ( 0, "Failed to update customPlugins: $output" );
    }

    return ( 1, "Activated in customPlugins: $new_value" );
}

sub _checkPerlModule {
    my ( $module, $min_version ) = @_;
    eval "require $module";
    return 0 if $@;
    if ( $min_version && $min_version ne '0' ) {
        eval { $module->VERSION($min_version) };
        return 0 if $@;
    }
    return 1;
}

sub _usage {
    my ($exitcode) = @_;
    print <<'USAGE';
Usage: lemonldap-ng-store COMMAND [OPTIONS]

Commands:
  add-store URL            Add an approved store URL
  remove-store URL         Remove a store URL
  list                     List available plugins
  info PLUGIN              Show plugin details
  install PLUGIN           Install a plugin
  remove PLUGIN            Remove an installed plugin
  installed                List installed plugins
  update                   Refresh store indexes
  check [PLUGIN]           Check for updates
  verify ARCHIVE           Verify a local archive
  rebuild                  Rebuild manager files (after LLNG upgrade)

Options:
  --store=URL              Use a specific store URL
  --search=TERM            Filter plugins by search term
  --tag=TAG                Filter plugins by tag
  --version=X.Y.Z          Install a specific version
  --force                  Skip compatibility checks
  --allow-overwrite        Allow overwriting existing files (e.g. core plugins)
  --activate               Add plugin to customPlugins (requires lemonldap-ng-cli)
  --state-file=PATH        Override state file path
  --cache-dir=PATH         Override cache directory
  --plugins-dir=PATH       Override manager plugins directory
  --help, -h               Show this help

Environment variables (override lemonldap-ng.ini):
  LLNG_DEFAULTCONFFILE     Path to lemonldap-ng.ini
  LLNG_STORE_URLS          Store URLs (comma-separated)
  LLNG_STORE_STATEFILE     State file path
  LLNG_STORE_CACHEDIR      Cache directory
  LLNG_STORE_OVERRIDESDIR  Manager overrides directory
  LLNG_STORE_GPGVERIFY     GPG verification mode (required/optional/disabled)
  LLNG_STORE_GPGKEYRING    GPG keyring path
USAGE
    exit $exitcode;
}

1;
