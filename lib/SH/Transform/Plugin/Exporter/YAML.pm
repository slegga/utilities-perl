package SH::Transform::Plugin::Exporter::YAML;
use Mojo::Base 'SH::Transform::Exporter',-signatures;
use Mojo::File 'path';
use YAML::Syck;

sub is_accepted($self, $args) {

    my $extname;
    if (exists $args->{file} && $args->{file}) {
        $extname = path($args->{file})->extname;
    }
    return 0 if ! defined $extname; 
    return 1 if $extname eq 'yaml' || $extname eq 'yml';
    return 0;
}

sub export($self,$args) {
    my $return;
    ...;
    return $return;
}
1;