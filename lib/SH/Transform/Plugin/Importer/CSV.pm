package SH::Transform::Plugin::Importer::CSV;
use Mojo::Base 'SH::Transform::Importer', -signatures;
use Mojo::File 'path';
use SH::CSV;
use Data::Printer;

=head1 NAME

SH::Transform::Plugin::Importer::CSV - Import from a CSV file. Use SH::CSV designed to import from a Lastpass export.

=head1 SYNOPSIS

    use SH::Transform::Plugin::Importer::CSV;
    my $imp =  SH::Transform::Plugin::Importer::CSV->new;
    my $args={file=>'data.csv'};
    my $ok = $imp->is_accepted($args);
    if ($ok) {
        my $hashes = importx($imp, $args);
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
    return 1 if path($args->{file})->extname eq 'csv';
    return 0;
}

sub importx($self,$args) {
    #aray of hasf refs
    my $c ={};
    $c->{$_}=$args->{$_} for keys %$args;
    delete $c->{file};
    $c->{column_with_extra}='url';
#    p $c;
    my $return = SH::CSV->new({ binary => 1} )->read($args->{file},$c);
             #headers => "auto"  , %$c);   # as array of hash  #

    return $return;
}
1;