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
use SH::Transform;

#use Carp::Always;

=encoding utf8

=head1 NAME

transform.pl - Read from source write to destination. Transform data to another format.

=head1 SYNOPSIS 

    $ transform.pl --source_file abc.json --target_file abc.yml
    # Produce a the abc.yml file with data from abc.json

    $ transform.pl --type sqlitetable --source_file t/data/unittest.db --source_table unittest --target_file def.yml
    # Produce yml file with data from database

    $ transform.pl --source_file abc.json
    # List data from abc.json

=head1 DESCRIPTION

Made for take a file, database etc and transform it to a new file database etc on another format.
All import data is put in a perl data structure, and then the perl structure is used to write to destination.



=head1 ATTRIBUTES

=head2 configfile - default to $CONFIG_DIR then $HOME/etc/<<scriptname>>.yml

=cut

option 'dryrun!',            'Print to screen instead of doing changes';
option 'source_file=s',      'Give the source file';
option 'source_type=s',      'Give the source type';
option 'source_table=s',      'Give the source table';
option 'destination_file=s', 'Give the destination file';
option 'destination_type=s', 'Give the destination type';


sub main {
    my $self = shift;
    # my @e = @{ $self->extra_options };
    # die "Extra arguments " . join(' ', @e);
    my $source = {};
    $source->{file} = $self->source_file if $self->source_file;
    $source->{type} = $self->source_type if $self->source_type;
    $source->{table} = $self->source_table if $self->source_table;
    my $destination = {};
    $destination->{file} = $self->destination_file if $self->destination_file;
    $destination->{type} = $self->destination_type if $self->destination_type;
    my $trans=SH::Transform->new;
    $trans->transform($source, $destination);

}

__PACKAGE__->new(options_cfg=>{extra=>0})->main();
