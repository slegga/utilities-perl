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

=encoding utf8

=head1 NAME

alert.pl - Notify with groupme account bot.

=head1 DESCRIPTION

Pipe text into script for sending a groupme to me. Fine for alerting about server errors etc.

=head1 ATTRIBUTES

=head2 configfile - default to $CONFIG_DIR then $HOME/etc/<scriptname>.yml

=cut

option 'dryrun!', 'Print to screen instead of doing changes';
has alert => sub{SH::Alert->new(dryrun=>$_[0]->dryrun)};

sub main($self) {
    my ($text, $i);
    while(<STDIN>) {
        $text .=$_;
        $i++;
        last if $i>50;
    }
    return if $text !~ /\w/;

    my $tx = $self->alert->groupme($text);
    if (! ref $tx) {
        say $tx;
        return;
    }
    if    ($tx->res->is_success)   { print $tx->res->body }
    elsif ($tx->res->is_error)     { say "Error: " . $tx->res->message }
    elsif ($tx->res->code == 301)  { say "Reroute to Location " . $tx->res->headers->location }
    else                      { say 'Whatever...' }
}

__PACKAGE__->new()->main();
