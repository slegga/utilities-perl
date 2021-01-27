package SH::Code::Template::Model;
use Mojo::Base 'SH::Code::Template';
use Mojo::Template;
use Mojo::Loader;
use Data::Dumper;
use Mojo::File 'path';

=head1 NAME

SH::Code::Template::Model - Template for Mojolicious Model class

=head1 DESCRIPTION

Plugin for template.pl. Template for a Mojolicous model class.

=head1 SYNOPSIS

template.pl --helptemplate

=head1 METHOD

=head2 name

=head2 help_text

=head2 required_variables

=head2 optional_variables

=head2 generate

=cut


sub name {'model'};
sub help_text {'Generate file lib/Model/<Modelname>.pm and t/<Modelname>.t'};

sub required_variables {[
    ['name',                'basename of script with out extendedname'],
    ['shortdescription',    'One line description of script'],
]};

sub optional_variables {[
    ['configfile',             'If set add code for reading configfile as a yml file'],
    ['sqlitefile',               'Name of SQLite file.'],
]};


sub generate {
    my $self = shift;
    my $main = shift;
    my %parameters = map { $_, $main->{$_} } keys %$main;

    my $p = $self->get_missing_param(\%parameters);
    say join(':', values %$p);
	$p = $self->pad_optional_param($p);
    $self->generate_file({path=>'lib/Model', filename=>$p->{name}.'.pm', parameters=>$p, ts => $self->xdata_section(__PACKAGE__, 'main.pm')})
        or die "Did not make the file ". $p->{name}.'.pm';

    $p->{pathname}= "lib/Model/".$p->{name}.'.pm';
    $self->generate_file({path=>'t', filename=>$p->{name}.'.t', parameters=>$p, ts => data_section(__PACKAGE__, 'test.t')})
        or die "Did not make the file ". $p->{name}.'.t';
	if ($p->{sqlitefile} && ! -e 'migrations/tabledef.sql')  {
		$self->generate_file({path=>'migrations', filename=>'tabledef.sql', parameters=>$p, ts => data_section(__PACKAGE__, 'tabledef.sql')})
		        or die "Did not make the file migrations/tabledef.sql";
	}
    path()->child('migrations')->make_path;
}

1;

__DATA__

@@main.pm
package Model::<%= $name %>;
use Mojo::Base -base, -signatures;
use Mojo::SQLite;
use open ':encoding(UTF-8)';




=head1 NAME

Model::<%= $name %>.pm - <%= $shortdescription %>

=head1 DESCRIPTION

<DESCRIPTION>

=head1 ATTRIBUTES

=head2 dbfile - default to $HOME/etc/<scripname>.db

Name of dbfile

=head2 sqlite

Default to a new Mojo::SQLite object

=head2 configfile - Default to $CONFIG_DIR else $HOME/etc/<scriptname>.yml

=head2 db

Default to a new Mojo::SQLite::Database object

=cut

has dbfile => $ENV{HOME}.'/etc/<%= $name %>.db';
has sqlite => sub {
	my $self = shift;
	if ( -f $self->dbfile) {
		return Mojo::SQLite->new()->from_filename($self->dbfile);
	} else {
		my $path = path($self->dbfile)->dirname;
		if (!-d "$path" ) {
			$path->make_path;
		}
		return Mojo::SQLite->new("file:".$self->dbfile);
	#	die "COULD NOT CREATE FILE ".$self->dbfile if ! -f $self->dbfile;
	}

};
has db => sub {shift->sqlite->db};


%
% if ($configfile) {
has configfile =>($ENV{CONFIG_DIR}||$ENV{HOME}.'/etc').'/' <%= $configfile %>;
has config => sub {YAML::Tiny::LoadFile($configfile};
% }

=head1 METHODS

=head2 read

...

=cut

sub read {
    my $self = shift;
    my $res = $self->db->query(q|select a, b from c|);
    die $res->stderr if ($res->err);
}

sub write {
    my $self = shift;
    my $hash =shift;
    my @keys = keys %$hash;
    my @values = values %$hash;
    my $res = $self->db->query('replace into c('.join(',',@keys).')', @values);
    die $res->stderr if ($res->err);
}
1;

@@test.t
use Mojo::Base -strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use Mojo::File 'path';

# <%= $name %>.pm - <%= $shortdescription %>

use Model::<%= $name %>;
% if ( $sqlitefile ) {
use File::Temp;
my $tempdir = File::Temp->newdir; # Deleted when object goes out of scope
my $tempfile = catfile $tempdir, 'test.db';
my $sql = Mojo::SQLite->new->from_filename($tempfile);
$sql->migrations->from_file('migrations/tabledefs.sql')->migrate;
% }
unlike(path('<%= $pathname %>')->slurp, qr{\<[A-Z]+\>},'All placeholders are changed');
my $m  = Model::<%= $name %>->new(debug=>1);
is_deeply($m->read('a'), {x=>'y'}, 'output is ok');
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

