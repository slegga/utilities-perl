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
use Mojo::UserAgent;
use Sys::Hostname;

use  YAML::Tiny;

#use Carp::Always;

=encoding utf8

=head1 NAME

alert.pl - Notify with groupme account bot.

=head1 DESCRIPTION

Pipe text into script for sending a groupme to me. Fine for alerting about server errors etc.

=head1 ATTRIBUTES

=head2 configfile - default to $CONFIG_DIR then $HOME/etc/<scriptname>.yml

=cut

has configfile =>($ENV{CONFIG_DIR}||$ENV{HOME}.'/etc').'/groupme-bot.yml';
has config => sub { YAML::Tiny::LoadFile(shift->configfile) };
option 'dryrun!', 'Print to screen instead of doing changes';
has ua =>sub{Mojo::UserAgent->new};
has url => sub{Mojo::URL->new('https://api.groupme.com/v3/bots/post')};

sub main {
    my $self = shift;
    my @e = @{ $self->extra_options };
    my $bot_id = $self->config->{bot_id};
    my ($short_hostname) = split /\./, hostname(); # Split by '.', keep the first part
    my $identity = getpwuid( $< ).'@'.$short_hostname.': ';
    my $text='';
    my $i=0;
    while(<STDIN>) {
        print $_;
        $text .=$_;
        $i++;
        last if $i>50;
    }
    return if !$text;
    my $payload ={
        bot_id=>$bot_id,
        text =>$identity . $text
    };

    $self->ua->post($self->url=>json=>$payload);
}

__PACKAGE__->new(options_cfg=>{extra=>1})->main();
