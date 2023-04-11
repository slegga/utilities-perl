package SH::Transform::Exporter;
use Mojo::Base -base, -signatures;

sub is_accepted($self,$args) {
    die "__SUB__ is not defined in __CALLER__";
}

sub export($self, $args) {
    die "__SUB__ is not defined in __CALLER__";
}


1;
