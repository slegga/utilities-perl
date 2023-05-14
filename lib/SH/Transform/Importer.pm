package SH::Transform::Importer;
use Carp 'confess';
use Mojo::Base -base, -signatures;

=head1 NAME

SH::Transform::Importer

=head1 SYNOPSIS

    package SH::Transform::Plugin::Importer::CSV;
    use Mojo::Base 'SH::Transform::Importer';
    use Text::CSV;
    sub is_acceptedb{
        ...
    }

    sub importx {
        ...;
    }



=head1 DESCRIPTION

Base class for modules named SH::Transform::Plugin::Importer::*
Import method crash with oder method. Rename to importx


=head1 METHODS

=head2 is_accepted

Dies if not overrrided.

Decide if this modue can be used or not.

=head2 importx

Dies if not overrrided.

Import

=cut

sub is_accepted($self,$args) {
    my $x = (caller(0))[3];
    confess  $x ." is not defined in " .join(',',caller());
}

sub importx($self, $args) {
    my $x = (caller(1))[3];
    die  $x." is not defined in " .join(',',caller());
}


1;
