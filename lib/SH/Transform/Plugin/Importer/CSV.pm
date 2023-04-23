package SH::Transform::Plugin::Importer::CSV;
use Mojo::Base 'SH::Transform::Importer', -signatures;
use Mojo::File 'path';
use Text::CSV;
#use Data::Printer;

sub is_accepted($self, $args) {
    return 1 if path($args->{file})->extname eq 'csv';
    return 0;
}

sub import($self,$args) {
    #aray of hasf refs
    my $c ={};
    $c->{$_}=$args->{$_} for keys %$args;
    delete $c->{file};
#    p $c;
    my $return = Text::CSV->new->csv (in => $args->{file},
               headers => "auto", %$c);   # as array of hash
#    p $return;
    return $return;
}
1;