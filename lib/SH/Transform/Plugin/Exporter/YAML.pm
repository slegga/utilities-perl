package SH::Transform::Plugin::Exporter::YAML;
use Mojo::Base 'SH::Transform::Exporter',-signatures;
use Mojo::File 'path';
use YAML::Syck;

=head1 NAME

SH::Transform::Plugin::Exporter::YAML - create file and fill it with data in yaml format

=head1 SYNOPSIS

    use SH::Transform;
    my $trans = SH::Transform->new(Exporter=>SH::Transform::Plugin::Exporter::YAML->new);
    $trans->transform({file=>'test.json'},{file=>'test.yaml'});

=head1 DESCRIPTION

Enable export to yaml formated file.

=head1 METHODS

=head2 is_accepted

Mark if this is the right to use decided by args.

=head2 export

Examine data, transform, and export data to YAML file given as input.

=cut


sub is_accepted($self, $args) {

    my $extname;
    if (exists $args->{file} && $args->{file}) {
        $extname = path($args->{file})->extname;
    }
    else {
        return 0;
    }
    return 1 if $extname eq 'yaml' || $extname eq 'yml';
    return 0;
}

sub export($self,$args,$data) {
    die "Missing argument file" . encode_json($args) if ! $args->{file};
    DumpFile($args->{file}, $data);
}
1;