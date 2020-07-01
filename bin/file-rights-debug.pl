#!/usr/bin/env perl

use Mojo::File 'path';

my $lib;
BEGIN {
    my $gitdir = Mojo::File->curfile;
    my @cats = @$gitdir;
    while (my $cd = pop @cats) {
        if ($cd eq 'git') {
            $gitdir = path(@cats,'git');
            last;
        }
    }
    $lib =  $gitdir->child('utilities-perl','lib')->to_string;
};
use lib $lib;
use SH::UseLib;
use SH::ScriptX;
use Mojo::Base 'SH::ScriptX';
use open qw(:std :utf8);
use YAML::Tiny;
use Clone 'clone';
use Fcntl ':mode';
use SH::PrettyPrint;
#use Carp::Always;

=encoding utf8

=head1 NAME

file-rights-debug.pl - To analyze why not file is readable for user.

=head1 DESCRIPTION

nginx user on piano do not have rights to read a file. It is hard to analyze.
It is a good idea to run this as root


=cut

option 'dryrun!', 'Print to screen instead of doing changes';
option 'user=s',  'Anayze based on view from user.';

sub main {
    my $self = shift;
    my @e = @{ $self->extra_options };
    my $filenamepath = shift @e;
    my $file = path($filenamepath);
    my $result=[];
    my @links =(clone($file));
    while (my $tf = shift(@links)) {
        my $first = 1;
        do {
            my @stat  = stat("$tf");
            my $mode = $stat[2];
            my $user_rwx      = ($mode & S_IRWXU) >> 6;
            my $group_rwx    = ($mode & S_IRWXG) >> 3;
            my $other_rwx =  $mode & S_IRWXO;            my $link =       readlink "$tf";
            if ($link && $first != 1 && $link ne $tf->to_string ) {
                push @links, path($link);
                next;
            }
            $first = 0;
            push @$result,{name=>"$tf",
                user=>scalar getpwuid($stat[4]),
                group=>scalar getgrgid($stat[5]),
                user_rwx=> $user_rwx,
                group_rwx => $group_rwx,
                other_rwx=>$other_rwx,
                exists=> -e "$tf"||0
                };
            $tf = $tf->dirname;
        }while ( $tf->to_string ne '/');
        say SH::PrettyPrint::print_hashes($result,{columns => [qw/name user group user_rwx group_rwx other_rwx/]})
    }

}

__PACKAGE__->new(options_cfg=>{extra=>1})->main();
