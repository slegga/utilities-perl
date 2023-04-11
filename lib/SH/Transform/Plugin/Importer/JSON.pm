package SH::Transform::Plugin::Importer::JSON;
use Mojo::Base 'SH::Transform::Importer', -signatures;
use Mojo::File 'path';
use Mojo::JSON 'from_json';

sub is_accepted($self, $args) {
    return 1 if path($args->{file})->extname eq 'json';
    return 0;
}

sub import($self,$args) {
    my $return = from_json(path($args->{file})->slurp);
    return $return;
}
1;