#!/usr/bin/env perl
use Mojo::Base -strict;
use autodie;
use FindBin;
use File::Finder;
use File::Copy 'copy';
use File::Basename;
use YAML;
use lib "$FindBin::Bin/../lib";
use SH::Script qw/options_and_usage/;

=head1 NAME

file-forwarder.pl

=head1 DESCRIPTION

Script will copy files that is not yet copied from source to destination. The script will exit
when all files in source dir is copied to destination dir.
If computer or script is stopped before finished it will continue where is stopped.

Ment to be placed in a crontab like this.
 . source ~/perl5/....  file-forwarder.pl

This script needs an configuration file placed in ~/etc/file-forwarder.cfg.yml.

=head2 Configuration file

- '/from_dir':
    to_dir: '/to/dir'

=head2 done file

Is named ~/etc/file-forwarder.done.yml
When a file is successfully copied to to_dir the filepathname will be added to done-file.


=head1 SETUP

mount -t cifs -o username=$USER,password=$PASSWORD //$LOCALIP/media /mnt/smbmedia -o vers=1.0

=head2 file-forwarder.cfg.yml

Should be placed at ~/etc/file-forwarder.cfg.yml

'source dir'
    - 'destination dir'

=cut

#
#   START
#

my ( $opts, $usage, $argv ) =
    options_and_usage( $0, \@ARGV, "%c %o",
    [ 'homedir=s', 'Set alternative home dir for using non default configuration' ],
,{return_uncatched_arguments => 1});


#
#   MAIN
#



my $homedir = $opts->homedir || $ENV{HOME};
my $cfg_file = $homedir.'/etc/file-forwarder.cfg.yml';
my $done_file = $homedir.'/etc/file-forwarder.done.yml';

# Read configuration file
my $config = YAML::LoadFile($cfg_file);

# Read done file
my $done = YAML::LoadFile($done_file);

# Main loop
warn ref $config;
for my $source_dir (keys %$config) {
    my $destinations = $config->{$source_dir};
    for my $destination (@$destinations) {
        die "$source_dir is not a directory." if (! -d $source_dir);
        die "$destination is not a directory." if (! -d $destination);

    # file find all files in source. Next if status done else copy
        my @all_files = File::Finder->type('f')->in("$source_dir");
        my %done_files = map{$_,1} @{$done->{$source_dir} };
        my @candidates = grep {! exists $done_files{$_} && $done_files{$_} != 1 } @all_files;
        for my $cpfile(@candidates) {
            $cpfile = basename($cpfile);
            say "copy($source_dir/$cpfile, $destination/$cpfile)";
            copy("$source_dir/$cpfile", "$destination/$cpfile") or die "Ikke suksess";
            # when success copied a file write to done file
            push @{$done->{$source_dir} }, $cpfile;
            YAML::DumpFile($done_file, $done);
            say "$cpfile has been copied";
        }
    }
}
say "Finished!";
