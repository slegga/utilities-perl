package SH::Code::Template::ScriptX;
use Mojo::Base 'SH::Code::Template';
use Mojo::Template;
use Data::Dumper;
use Mojo::File 'path';

=head1 METHODS

=head2 name

=head2 help_text

=head2 required_variables

=head2 optional_variables

=head2 generate

=cut


sub name {'scriptx'};
sub help_text {'Generate <scriptname>.pl in bin and <scriptname>.t in t'};

sub required_variables {[
    ['name',                'basename of script with out extendedname'],
    ['shortdescription',    'One line description of script'],
]};



sub optional_variables {[
    ['configfile',          'If set add code for reading configfile as a yml file'],
    ['sqlitefile',          'Generate a script with sqlite support'],
]};


sub generate {
    my $self = shift;
    my $main = shift;
    my %parameters = map { $_, $main->{$_} } keys %$main;

    my $p = $self->get_missing_param(\%parameters);
    say join(':', values %$p);
    $p = $self->pad_optional_param($p);
    $self->generate_file({path=>'bin', filename=>$p->{name}.'.pl', parameters=>$p, ts => $self->xdata_section(__PACKAGE__, 'main.pl')}) or die "Did not make the file ". $p->{name}.'.pl';

    $p->{pathname}= "bin/".$p->{name}.'.pl';
    $self->generate_file({path=>'t', filename=>$p->{name}.'.t', parameters=>$p, ts => $self->xdata_section(__PACKAGE__, 'test.t')}) or die "Did not make the file ". $p->{name}.'.t';
	if ($p->{sqlitefile} && ! -e 'migrations/tabledef.sql')  {
		$self->generate_file({path=>'migrations', filename=>'tabledefs.sql', parameters=>$p, ts => $self->xdata_section(__PACKAGE__, 'tabledefs.sql')})
		        or die "Did not make the file migrations/tabledef.sql";
	}
}

1;

__DATA__

@@main.pl
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
use utf8;
use open ':encoding(UTF-8)';
% if ($configfile) {
use  YAML::Tiny;
}

#use Carp::Always;

=encoding utf8

=head1 NAME

<%= $name %>.pl - <%= $shortdescription %>

=head1 DESCRIPTION

<DESCRIPTION>

=cut

% if ($configfile) {
has configfile =>($ENV{CONFIG_DIR}||$ENV{HOME}.'/etc').'/<%= $configfile %>.yml';
has config => sub { YAML::Tiny::LoadFile($configfile) };
% }
option 'dryrun!', 'Print to screen instead of doing changes';

sub main {
    my $self = shift;
    my @e = @{ $self->extra_options };
}

__PACKAGE__->new(options_cfg=>{extra=>1})->main();

@@test.t
use Mojo::Base -strict;
use Test::More;
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
use Test::ScriptX;


# <%= $name %>.pl - <%= $shortdescription %>

unlike(path('<%= $pathname %>')->slurp, qr{\<[A-Z]+\>},'All placeholders are changed');
my $t = Test::ScriptX->new('bin/<%= $name %>.pl', debug=>1);
$t->run(help=>1);
$t->stderr_ok->stdout_like(qr{<%= $name%>});
done_testing;

@@tabledefs.sql
## sqllite migrations
-- 1 up
create table messages (message text);
insert into messages values ('I ♥ Mojolicious!');
-- 1 down
drop table messages;

-- 2 up (...you can comment freely here...)
create table stuff (whatever integer);
-- 2 down
drop table stuff;

