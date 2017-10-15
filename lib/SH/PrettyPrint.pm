package SH::PrettyPrint;
use Mojo::Base -strict;

sub print_arrayofarrays {
    my $ahr =shift;
    #   die "Expect array ref this is ". ref $ahr if (ref $ahr ne 'ARRAY' );
    for my $r(@$ahr) {
        say join("\t", @$r);
    }
}

1;

