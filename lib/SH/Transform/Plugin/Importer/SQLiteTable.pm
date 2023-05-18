package SH::Transform::Plugin::Importer::SQLiteTable;
use Mojo::Base 'SH::Transform::Importer', -signatures;
use Mojo::File 'path';
use Mojo::SQLite;
use Data::Printer;

=head1 NAME

SH::Transform::Plugin::Importer::SQLiteTable - Import from SQL Lite table

=head1 SYNOPSIS

    use SH::Transform::Plugin::Importer::SQLiteTable;
    my $imp =  SH::Transform::Plugin::Importer::SQLiteTable->new;
    my $ok = $imp->is_accepted({type=>'sqlitetable'});
    if ($ok) {
        my $hashes = $imp->importx({file=>'file.db', table=>'table'});
    }

=head1 DESCRIPTION

Import data as hashes ref from a sqlite table.

=head1 METHODS

=head2 is_accepted

API to mark if args require this to be used.

=cut

sub is_accepted($self, $args) {
    $DB::single=2;
    return 1 if exists $args->{type} && lc($args->{type}) eq 'sqlitetable';
    return 0;
}

=head2 importx

Import data based on given args

=cut

sub importx($self,$args) {
    my $sql = Mojo::SQLite->new('sqlite:'. $args->{file});
    my $return = $sql->db->query("select * from " . $args->{table})->hashes->to_array;
    return $return;
}

1;
