#!/usr/bin/env perl

use YAML::Tiny;
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
use utf8;
use open ':encoding(UTF-8)';
use Git::Repository;
use Data::Dumper;

=encoding utf8

=head1 NAME

pinstall.pl - Run tests and git push

=head1 DESCRIPTION

Check if every ting is ok and do git push.
Will stop if someting is wrong before git push.

=cut

option 'dryrun!', 'Print to screen instead of doing changes';

sub main {
    my $self = shift;

    # check if in basegit repo or die
    my $curdir = Mojo::File::curfile;
    $curdir = Mojo::File->new;
    die "You are not in a git-directory".$curdir->child('.git')->to_string if ! -d $curdir->child('.git')->to_string;
    # prove or die
    say `prove -l -Q --state save 2>/dev/null 1>/dev/null`;
    my $provedata = YAML::Tiny->read( $curdir->child('.prove')->to_string )->[0]->{tests};
#    say Dumper $provedata;
    for my $testfile(keys %$provedata) {
        die "$testfile did not pass. Please run prove -lv $testfile" if $provedata->{$testfile}->{last_result};
    }
    say "# git status";
    say " if dirty git add -A;git commit -a";
    say "# git push";
}

__PACKAGE__->new->main();
