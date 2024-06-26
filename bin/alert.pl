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
use Mojo::Base 'SH::ScriptX', -signatures;
use SH::Alert;
use Data::Printer;

=encoding utf8

=head1 NAME

alert.pl - Notify with groupme account bot.

=head1 DESCRIPTION

Pipe text into script for sending a groupme to me. Fine for alerting about server errors etc.

=head1 ATTRIBUTES

=head2 configfile - default to $CONFIG_DIR then $HOME/etc/<scriptname>.yml

=cut

option 'dryrun!', 'Print to screen instead of doing changes';
option 'ignore=s',  'Ignore alerting if regexp match';
has alert => sub{SH::Alert->new(dryrun=>$_[0]->dryrun)};

sub main($self) {
    my ($text, $i);
    while(<STDIN>) {
        $text .=$_;
        $i++;
        last if $i>50;
    }
    return if ! $text;
    return if $text !~ /\w/;
    if ($self->ignore) {
        my $re = $self->ignore;
        return if $text =~ /$re/;
    }
    if ($self->dryrun) {
        say "DRYRUN: alert will report this text";
        say $text;
        return;
    }
    $self->alert->groupme($text);
}

__PACKAGE__->new()->main();
