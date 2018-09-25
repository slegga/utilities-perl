#!/usr/bin/env perl
use Mojo::File 'path';
use autodie;
use FindBin;
use Data::Dumper;
use File::Finder;
use File::Copy 'copy';
use File::Basename;
use Encode;
use YAML::Tiny;
use utf8;
use lib "$FindBin::Bin/../lib";
use SH::ScriptX;  # call import
use Mojo::Base 'SH::ScriptX';

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

#my ( $opts, $usage, $argv ) =
#    options_and_usage( $0, \@ARGV, "%c %o",
option   'homedir=s', 'Set alternative home dir for using non default configuration';
#,{return_uncatched_arguments => 1});


#
#   MAIN
#


__PACKAGE__->new->main;
sub main {
	my $self = shift;
	my $homedir = $self->homedir || $ENV{HOME};
	my $cfg_file = $homedir.'/etc/file-forwarder.cfg.yml';
	my $done_file = $homedir.'/etc/file-forwarder.done.yml';

	if (! -e $done_file ) {
	    `touch $done_file`;
	}
	# Read configuration file
	say "Read config file ".$cfg_file;
	my $config = YAML::Tiny::LoadFile($cfg_file);

	# Read done file
	if (! -e $done_file) {
	    qx(touch $done_file);
	}
	my $done = YAML::Tiny::LoadFile($done_file);

	# Main loop
	# warn ref $config;
	for my $source_dir (keys %$config) {
	    my $source = path($source_dir);
	    die "Source directory: $source_dir does not exists" if ! -d $source_dir;
	    my $destinations = $config->{$source_dir};
	    for my $destination (keys %$destinations) {
	        my $dest_cfg = $destinations->{$destination};
	        if (! -d $destination) {
	            if (!ref $dest_cfg || !exists $dest_cfg->{mount_cmd} ) {
	                die "Destination: $destination is not a directory.";
	            }
	            my $cmd = $dest_cfg->{mount_cmd};
	            `$cmd`;
	            if (! -d $destination || $@) {
	                warn $@;
	                warn $dest_cfg->{mount_cmd};
	                die "Destination $destination is not a directory or did not mount.";
	            }
	        }
	    # file find all files in source. Next if status done else copy
	        #my @all_files = File::Finder->type('f')->in("$source_dir");
	        my @all_files =map{substr $_,length($source_dir)} map {decode('UTF8',$_, Encode::FB_CROAK)} $source->list_tree->each;
	        my %done_files = map{$_,1} @{$done->{$source_dir}};
	        my @candidates = grep {! exists $done_files{$_} || $done_files{$_} != 1 } @all_files;
	        for my $cpfile(@candidates) {
	            # my $basecpfile = basename($cpfile);
	#            die $cpfile.'     '.$basecpfile;
	            #say "$source_dir$cpfile -d:".-d("$source_dir$cpfile");
	            #say "RARE GREIER NÅR IKKE DETTE ER DIRECTORY test $source_dir$cpfile". -d "$source_dir$cpfile";
	            if ( -d "$source_dir$cpfile" ) {
	                if (! -d "$destination$cpfile") {
	                    mkdir "$destination$cpfile" ||die "mkdir $!$@";
	                }
	            # Check if file exists and is readonly, then skip
	            } elsif (-e "$destination$cpfile" && ! -w "$destination$cpfile"
	            && -s "$source_dir$cpfile" == -s "$destination$cpfile" ) {
	                say "$destination$cpfile exists. Do notthing"
	            } else {
	                say "copy($source_dir$cpfile, $destination$cpfile)";
	                copy("$source_dir$cpfile", "$destination$cpfile") or die "copy ERROR: $! $@";
	                say "$cpfile has been copied";
	            }
	            # when success copied a file write to done file
	            push @{$done->{$source_dir} }, $cpfile;
	            YAML::Tiny::DumpFile($done_file, $done);
	        }
	    }
	}
	say "Finished!";
}
1;
