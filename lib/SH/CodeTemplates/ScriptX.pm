package SH::CodeTemplates::ScriptX;
use Mojo::Base 'SH::CodeTemplates';
use Mojo::Template;
use Mojo::Loader qw(data_section);
use Data::Dumper;
use Mojo::File 'path';

sub name {'scriptx'};
sub help_text {'Generate <scriptname>.pl in bin and <scriptname>.t in t'};

sub required_variables {[
    ['name',                'basename of script with out extendedname'],
    ['shortdescription',    'One line description of script'],
]};

sub generate {
    my $self = shift;
    my $main = shift;
    my %parameters = map { $_, $main->{$_} } keys %$main;
    my $p = $self->get_missing_param(\%parameters);
    say join(':', values %$p);
    $self->generate_file({path=>'bin', filename=>$p->{name}.'.pl', parameters=>$p, ts => data_section(__PACKAGE__, 'main')}) or die "Did not make the file ". $p->{name}.'.pl';
}

1;

__DATA__

@@main
#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use UseLib;
use SH::ScriptX;
use Mojo::Base 'SH::ScriptX';
#use Carp::Always;

=head1 NAME

<%= $name %>.pl - <%= $shortdescription %>

=head1 DESCRIPTION

<DESCRIPTION>

=cut

has config;
option 'dryrun!', 'Print to screen instead of doing changes';

 sub main {
    my $self = shift;
    my @e = $self->extra_options;
}

__PACKAGE__->new(options_cfg=>{extra=>1})->main();

@@test.t
use Test::More;
