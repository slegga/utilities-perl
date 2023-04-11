package SH::Transform::Exporter;
use Mojo::Base -base, -signatures;

sub is_accepted($self,$args) {
    my ($x,$y) = ((caller(0))[3], (caller(0))[0]);
    die  $x.' '. $y ." is not defined in " .join(',',caller());
}

sub export($self, $args, $data) {
    my ($x,$y) = ((caller(0))[3], (caller(0))[0]);
    die  $x.' '. $y ." is not defined in " .join(',',caller());
}


1;
