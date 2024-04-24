package SH::Alert;
use Mojo::File 'path';
use Mojo::Base -signatures,-base,-strict;

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
use open qw(:std :utf8);
use Mojo::UserAgent;
use Sys::Hostname;
use  YAML::Tiny;
use Mojo::JSON 'encode_json';
use Data::Printer;


=encoding utf8

=head1 NAME

SH::Alert - Notify with groupme account bot.

=head1 SYNOPSIS

    use SH::Alert;
    my $alert = SH::Alert->new;
    $alert->groupme("Groupme message");

=head1 DESCRIPTION

Module for sending groupme message from a bot. Nice for alerting about server errors etc.

=head2 Prequeries

You need a Groupme account and one or more groupme bots.

Create account at www.groupme.com

Create bots at dev.groupme.com.

Put data into the config file listed below.

=head1 ATTRIBUTES

=head2 configfile - default to $CONFIG_DIR then $HOME/etc/groupme.yml

=head2 Configfile content

    ---
    url_base: https://api.groupme.com/v3/bots/post
    default_bot: bot1
    bots:
        bot1:
            bot_id: 01234567890abcde
            description: Direct messages
        bot2:
            bot_id: bot_id: abcdeabcde
            description: Write to another group.


=cut

has configfile =>($ENV{CONFIG_DIR}||$ENV{HOME}.'/etc').'/groupme-bot.yml';
has config => sub { YAML::Tiny::LoadFile(shift->configfile) };
has ua =>sub{
    my $ua = Mojo::UserAgent->new;
    # Detect proxy servers from environment
    $ua->proxy->detect;
    return $ua;
};
has url => sub{Mojo::URL->new('https://api.groupme.com/v3/bots/post')};
has 'dryrun';

=head1 METHODS

=head2 groupme

    $alert->groupme("Message","botname");

Send a message to Groupme via a bot.

=cut

sub groupme($self, $message, $bot = undef) {
    return if $message !~ /\w/;
    $bot //= $self->config->{default_bot};
    my $bot_id = $self->config->{bots}->{$bot}->{bot_id};
    my ($short_hostname) = split /\./, hostname(); # Split by '.', keep the first part
    my $identity = getpwuid( $< ).'@'.$short_hostname.': ';
    my $payload ={
        bot_id=>$bot_id,
        text =>$identity . $message
    };
    if ($self->dryrun) {
        say "DryRun no communication with api.groupme.com";
        say encode_json($payload) . $self->url ;
    }

    my $tx = $self->ua->post($self->url=>json=>$payload);

    if    ($tx->res->is_success)   { return 1 }
    elsif ($tx->res->is_error)     { die "Error: " . $tx->res->message }
    elsif (! $tx->res->can('code') || ! $tx->res->code )  {
        p($tx->res);
        die "Error. Strange return: " . $tx->req->to_string;
    }
    elsif ($tx->res->code == 404)  { die "404 Path not found '" . $tx->req->url . "'" }
    else                      { warn "code: ". $tx->res->code; warn $tx->req->to_string;p $tx; ...; }

}

1;