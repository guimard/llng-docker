package Lemonldap::NG::Common::Store::Install;

use strict;
use warnings;
use Archive::Tar;
use File::Basename qw(dirname basename);
use File::Copy     qw(copy);
use File::Path     qw(make_path remove_tree);
use File::Find;
use File::Temp qw(tempdir);
use JSON;

our $VERSION = '2.23.0';

# Default paths - placeholders replaced during installation
my $DEFAULT_PORTALTEMPLATESDIR = '/usr/share/lemonldap-ng/portal/templates';
my $DEFAULT_PORTALSTATICDIR    = '/usr/share/lemonldap-ng/portal/htdocs/static';
my $DEFAULT_MANAGERSTATICDIR   = '/usr/share/lemonldap-ng/manager/htdocs/static';

# Derive INSTALLSITELIB from where this module was loaded
my $DEFAULT_INSTALLSITELIB;
if ( my $path = $INC{'Lemonldap/NG/Common/Store/Install.pm'} ) {
    ( $DEFAULT_INSTALLSITELIB = $path ) =~
      s|/Lemonldap/NG/Common/Store/Install\.pm$||;
}

# Mapping of archive directories to system destinations
my %DIR_MAP = (
    'lib'               => \$DEFAULT_INSTALLSITELIB,
    'manager-overrides' => undef,    # handled via managerOverridesDir config
    'portal-templates'  => \$DEFAULT_PORTALTEMPLATESDIR,
    'portal-static'     => \$DEFAULT_PORTALSTATICDIR,
    'manager-static'    => \$DEFAULT_MANAGERSTATICDIR,
);

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {
        managerOverridesDir => $args{managerOverridesDir}
          || '/etc/lemonldap-ng/manager-overrides.d',
        allowOverwrite => $args{allowOverwrite} || 0,
    }, $class;
    return $self;
}

# Extract and validate a plugin archive
# Returns (success, plugin_info_or_error, extracted_dir)
sub extractAndValidate {
    my ( $self, $archive_path ) = @_;

    # Extract to temp directory
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $tar    = Archive::Tar->new();

    unless ( $tar->read($archive_path) ) {
        return ( 0, "Failed to read archive: " . $tar->error(), undef );
    }

    # Security: validate all paths before extraction
    for my $file ( $tar->list_files() ) {
        if ( $file =~ /\.\./ ) {
            return ( 0, "Archive contains path traversal: $file", undef );
        }
    }

    $tar->setcwd($tmpdir);
    unless ( $tar->extract() ) {
        return ( 0, "Failed to extract archive: " . $tar->error(), undef );
    }

    # Find the plugin root directory (first level dir in archive)
    opendir my $dh, $tmpdir or return ( 0, "Cannot read temp dir: $!", undef );
    my @entries = grep { $_ !~ /^\./ && -d "$tmpdir/$_" } readdir $dh;
    closedir $dh;

    unless ( @entries == 1 ) {
        return ( 0, "Archive must contain exactly one top-level directory",
            undef );
    }

    my $plugin_dir = "$tmpdir/$entries[0]";

    # Read and validate plugin.json
    my $meta_file = "$plugin_dir/plugin.json";
    unless ( -r $meta_file ) {
        return ( 0, "Archive missing plugin.json", undef );
    }

    open my $fh, '<', $meta_file
      or return ( 0, "Cannot read plugin.json: $!", undef );
    local $/;
    my $content = <$fh>;
    close $fh;

    my $meta;
    eval { $meta = JSON->new->utf8->decode($content) };
    if ($@) {
        return ( 0, "Invalid plugin.json: $@", undef );
    }

    # Validate required fields
    for my $field (qw(name version)) {
        unless ( $meta->{$field} ) {
            return ( 0, "plugin.json missing required field: $field", undef );
        }
    }

    # Validate Perl modules are in Lemonldap/NG/ namespace
    if ( -d "$plugin_dir/lib" ) {
        my @bad_files;
        File::Find::find( {
                wanted => sub {
                    return unless /\.pm$/;
                    my $rel = $File::Find::name;
                    $rel =~ s|^\Q$plugin_dir/lib/\E||;
                    unless ( $rel =~ m|^Lemonldap/NG/| ) {
                        push @bad_files, $rel;
                    }
                },
                no_chdir => 1,
            },
            "$plugin_dir/lib"
        );
        if (@bad_files) {
            return (
                0,
                "Perl modules must be in Lemonldap::NG:: namespace. "
                  . "Invalid: "
                  . join( ', ', @bad_files ),
                undef
            );
        }
    }

    return ( 1, $meta, $plugin_dir );
}

# Install files from extracted plugin directory
# Returns (success, error_or_files_list)
sub installFiles {
    my ( $self, $plugin_dir, $meta ) = @_;

    my @installed_files;
    my @warnings;

    for my $src_dir ( sort keys %DIR_MAP ) {
        my $src_path = "$plugin_dir/$src_dir";
        next unless -d $src_path;

        # Determine destination
        my $dest;
        if ( $src_dir eq 'manager-overrides' ) {
            $dest = $self->{managerOverridesDir};
        }
        else {
            my $ref = $DIR_MAP{$src_dir};
            $dest = $$ref;
        }

        # Skip if placeholder not replaced (component not installed)
        if ( $dest =~ /^__.*__$/ ) {
            push @warnings,
              "Skipping $src_dir: destination not configured ($dest)";
            next;
        }

        # Create destination if it's manager-overrides (small dedicated dir)
        if ( $src_dir eq 'manager-overrides' && !-d $dest ) {
            eval { make_path( $dest, { mode => 0755 } ) };
            if ($@) {
                push @warnings, "Skipping $src_dir: cannot create $dest: $@";
                next;
            }
        }

        # Skip if destination doesn't exist
        unless ( -d $dest ) {
            push @warnings,
              "Skipping $src_dir: destination directory does not exist ($dest)";
            next;
        }

        # Copy files
        my ( $ok, $files, $err ) = $self->_copyTree( $src_path, $dest );
        unless ($ok) {

            # Rollback already installed files
            $self->removeFiles( \@installed_files );
            return ( 0, "Failed to install $src_dir: $err" );
        }
        push @installed_files, @$files;
    }

    # Print warnings
    for my $w (@warnings) {
        print "  $w\n";
    }

    return ( 1, \@installed_files );
}

# Copy a directory tree, checking for core file overwrites
# Returns (success, files_list, error)
sub _copyTree {
    my ( $self, $src, $dest ) = @_;

    my @files;

    File::Find::find( {
            wanted => sub {
                my $rel = $File::Find::name;
                $rel =~ s|^\Q$src\E/?||;
                return unless $rel;    # Skip root

                my $src_full  = "$src/$rel";
                my $dest_full = "$dest/$rel";

                if ( -d $src_full ) {

                    # Create directory
                    unless ( -d $dest_full ) {
                        make_path( $dest_full, { mode => 0755 } )
                          or do {
                            $self->{_error} = "Cannot create $dest_full: $!";
                            return;
                          };
                        push @files, $dest_full;
                    }
                }
                else {
                    # Check for core file overwrite
                    if ( -e $dest_full ) {
                        if ( $self->{allowOverwrite} ) {
                            print "  Overwriting existing file: $dest_full\n";
                        }
                        else {
                            $self->{_error} =
"Refusing to overwrite existing file: $dest_full (use --allow-overwrite)";
                            return;
                        }
                    }

                    # Ensure parent directory exists
                    my $parent = dirname($dest_full);
                    unless ( -d $parent ) {
                        make_path( $parent, { mode => 0755 } );
                    }

                    # Copy file
                    copy( $src_full, $dest_full )
                      or do {
                        $self->{_error} = "Cannot copy to $dest_full: $!";
                        return;
                      };

                    chmod 0644, $dest_full;
                    push @files, $dest_full;
                }
            },
            no_chdir => 1,
        },
        $src
    );

    if ( $self->{_error} ) {
        my $err = $self->{_error};
        delete $self->{_error};
        return ( 0, \@files, $err );
    }

    return ( 1, \@files, undef );
}

# Remove installed files (for uninstall or rollback)
sub removeFiles {
    my ( $self, $files ) = @_;

    # Remove files in reverse order (deepest first)
    for my $file ( reverse @$files ) {
        if ( -f $file ) {
            unlink $file or warn "Cannot remove $file: $!\n";
        }
        elsif ( -d $file ) {

            # Only remove if empty
            rmdir $file;    # silently fails if not empty, which is fine
        }
    }
}

# Run llng-build-manager-files if available
# Returns (success, message)
sub rebuildManager {
    my ($self) = @_;
    my $plugins_dir = $self->{managerOverridesDir};

    # Find llng-build-manager-files
    my $cmd = _findBuildScript();
    unless ($cmd) {
        return ( 1,
            'llng-build-manager-files not found, skipping manager rebuild' );
    }

    unless ( -d $plugins_dir ) {
        return ( 1,
            "Manager plugins dir not found ($plugins_dir), skipping rebuild" );
    }

    my $output = `$cmd --plugins-dir='$plugins_dir' 2>&1`;
    my $exit   = $? >> 8;

    if ( $exit != 0 ) {
        return ( 0, "Manager rebuild failed (exit $exit):\n$output" );
    }

    return ( 1, 'Manager files rebuilt successfully' );
}

# Placeholder __BINDIR__ is replaced at install time by the Makefile
my $DEFAULT_BINDIR = '/usr/share/lemonldap-ng/bin';

sub _findBuildScript {
    my $name = 'llng-build-manager-files';

    # First, look in the install BINDIR
    if ( $DEFAULT_BINDIR !~ /^__/ ) {
        my $path = "$DEFAULT_BINDIR/$name";
        return $path if -x $path;
    }

    # Fallback to PATH
    for my $dir ( split /:/, $ENV{PATH} || '' ) {
        my $path = "$dir/$name";
        return $path if -x $path;
    }
    return undef;
}

1;
