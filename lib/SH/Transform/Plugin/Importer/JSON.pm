package SH::Transform::Plugin::Importer::JSON;
use Mojo::Base 'SH::Transform::Importer', -signatures;
use Mojo::File 'path';
use JSON::PP;

sub is_acceptable($self, $args) {
    return 1 if path($args->{file})->extname eq 'json';
    return 0;
}

sub import($self,$args) {
    my $return;
    ...;
    return $return;
}
1;