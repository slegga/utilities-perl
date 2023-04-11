package SH::Transform;
use Mojo::Base -base, -signatures, -strict;
use Module::Pluggable require=>1;
use Mojo::JSON qw /encode_json/;

=head1 NAME

SH::Transform - Main object for transforming data from one source to another source.

=head1 SYNOPSIS

    my $trans = SH::Transform->new;
    my $ok = $trans->transform({file=>'test.json'}, {file=>'test.yaml'});

=head1 DESCRIPTION

Transform from one data set to another format.

=head1 ATTRIBUTES

=head2 importer

An object with SH::TRansform::Pluggins::Importer as the parent.
Responsible for the data input.

=head2 exporter

An object with SH::Tranform::Pluggins::Exporter as the parent
Responsible for the output of the data.

=cut

has _importers => sub($self) {
    my $return = [];
    for my $plugin($self->plugins) {
        die $plugin;
        if (ref $plugin =~ /^SH::Transform::Plugin::Importer::/) {
            push @$return, $plugin;
        }
    }
    die "No Importer plugins are awailable" if ! @$return;
    return $return;
};

has _exporters => sub($self) {
    my $return=[];
    for my $plugin($self->plugins) {
        if (ref $plugin =~ /^SH::Transform::Plugin::Exporter::/) {
            push @$return, $plugin;
        }
    }
    die "No Exporter plugins are awailable" if ! @$return;
    return $return;
};

has importer => sub($self) {
    my $importer;

    for my $imp(@{$self->_importers}) {
        if ($imp->accept($self->importer_args)) {
            die "More than one importer $importer and $imp for ".encode_json($self->importer_args) if $importer;
        }
        $importer = $imp;
    }
    die "No Importers can import from args: " .encode_json($self->importer_args) if ! $importer;
    return $importer;
};

has exporter => sub($self) {
    my $exporter;

    die "No Exporters can export from args: " .encode_json($self->exporter_args) if ! $exporter;
    for my $exp(@{$self->_exporters}) {
        if ($exp->accept($self->exporter_args)) {
            die "More than one exporter $exporter and $exp for ".encode_json($self->exporter_args) if $exporter;
        }
        $exporter = $exp;
    }
    return $exporter;
};

has 'importer_args';
has 'exporter_args';

=head1 METHODS

=head2 transform

    my $ok = SH::Transform->new->transform({file=>'test.json'}, {file=>'test.yaml'});

Main method to produce a file, output, database inserts etc(export) from data from a source(import) file, database etc.

Takes a importer hash reference as argument and an exporter hash reference as argument

=head3 importer args

    file => File to import from in format as the file extention.

=head3 exporter args

    file => File to create and place the data in given data or as the file extentions says

=cut

sub transform($self, $importer_args,$exporter_args) {

    if (! ref $importer_args eq 'HASH') {
        die "Missing \$importer_args ".($importer_args//'__UNDEF__') if ! $self->importer_args;
    }
    else {
        $self->importer_args($importer_args);
    }

    if (! ref $exporter_args eq 'HASH') {
        die "Missing \$exporter_args ".($exporter_args//'__UNDEF__') if ! $self->exporter_args;
    }
    else {
        $self->exporter_args($exporter_args);
    }

    my $data = $self->importer->import($self->importer_args);
    return $self->exporter->export($self->exporter_args, $data);
}

1;