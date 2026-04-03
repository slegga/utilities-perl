package SH::Transform::Exporter;
use Mojo::Base -base, -signatures;

=head1 NAME

SH::Transform::Exporter

=head1 SYNOPSIS

    package SH::Transform::Plugin::Exporter::CSV;
    use Mojo::Base 'SH::Transform::Exporter';
    use Text::CSV;

    sub is_accepted {
        ...;
    }

    sub export {
        ...;
    }

=head1 DESCRIPTION

Base class for modules named SH::Transform::Plugin::Exporter::*

=head1 METHODS

=head2 is_accepted

Dies if not overridden.

Decide if this module can be used or not.

=head2 export

Dies if not overridden.

Import

=cut


sub is_accepted($self,$args) {
    my ($x,$y) = ((caller(0))[3], (caller(0))[0]);
    die  $x.' '. $y ." is not defined in " .join(',',caller());
}

sub export($self, $args, $data) {
    my ($x,$y) = ((caller(0))[3], (caller(0))[0]);
    die  $x.' '. $y ." is not defined in " .join(',',caller());
}


1;
