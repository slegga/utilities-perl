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
use SH::Email::ToHash;
use Mojo::File qw 'path';
use Data::Dumper;

#use Carp::Always;

=encoding utf8

=head1 NAME

dump-email-hash.pl - Dump email hash text

=head1 DESCRIPTION

Dump email to hash result. Made for debugging hard to do emails.

=head1 ATTRIBUTES

=head2 configfile - default to $CONFIG_DIR then $HOME/etc/<<scriptname>>.yml

=cut

option 'dryrun!', 'Print to screen instead of doing changes';

sub main {
    my $self = shift;
    my @e = @{ $self->extra_options };
    my $file = $e[0];
    my $dumper = SH::Email::ToHash->new;
    my $emailfile = path($file);
    if (! -f "$emailfile") {
        die "Can't open fiel $file, file does not exists";
    }
    my $dump = $dumper->msgtext2hash(path($file)->slurp);
    print Dumper $dump;
}

__PACKAGE__->new(options_cfg=>{extra=>1})->main();
