package SH::Transform::Importer;
use Carp 'confess';
use Mojo::Base -base, -signatures;

sub is_accepted($self,$args) {
    my $x = (caller(0))[3];
    confess  $x ." is not defined in " .join(',',caller());    
}

sub import($self, $args) {
    my $x = (caller(1))[3];
    die  $x." is not defined in " .join(',',caller());
}


1;
