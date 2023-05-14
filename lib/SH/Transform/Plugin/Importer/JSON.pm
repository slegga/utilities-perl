package SH::Transform::Plugin::Importer::JSON;
use Mojo::Base 'SH::Transform::Importer', -signatures;
use Mojo::File 'path';
use Mojo::JSON 'from_json';

=head1 NAME

SH::Transform::Plugin::Importer::JSON - Import from SQL Lite table

=head1 SYNOPSIS

    use SH::Transform::Plugin::Importer::JSON;
    my $imp =  SH::Transform::Plugin::Importer::JSON->new;
    my $ok = $imp->is_accepted({file=>'data.json'});
    if ($ok) {
        my $hashes = $imp->importx({file=>'data.json'});
    }

=head1 DESCRIPTION

Import data as hashes ref from a JSON file.

=head1 METHODS

=head2 is_accepted

API to mark if args require this to be used.

=head2 importx

Import data based on given args.

=cut


sub is_accepted($self, $args) {
    return 1 if path($args->{file})->extname eq 'json';
    return 0;
}

sub importx($self,$args) {
    my $return = from_json(path($args->{file})->slurp);
    return $return;
}
1;