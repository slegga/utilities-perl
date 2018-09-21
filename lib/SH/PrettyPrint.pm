package SH::PrettyPrint;
use Mojo::Base -strict;

=head1 NAME

SH::PrettyPrint

=head1 FUNCTIONS

=head2 print_arrays

Print arrays with tab as separator

=cut

sub print_arrays {
    my $aar =shift;
    #   die "Expect array ref this is ". ref $ahr if (ref $ahr ne 'ARRAY' );
    for my $r(@$aar) {
        say join("\t", @$r);
    }
}

=head2 print_hashes

Print hashes pretty.

Takes: array ref of hashes ref

Print this with header and rows.

=cut

sub print_hashes {
	my $ahr = shift;
	my @keys = sort keys %{$ahr->[0]};

	# Calculate size

	my %size;
	for my $key (@keys) {
		$size{$key} = length($key);
	}

	for my $row( @$ahr ) {
		for my $key (@keys) {
			if ($size{$key} < length( $row->{$key} )) {
				$size{$key} = length( $row->{$key} );
			}
		}

	}

	for my $key (@keys)	 {
		my $out = "%".-$size{$key}."s ";
		printf $out,$key;
	}
	print "\n";
	for my $row( @$ahr ) {
		for my $key (@keys) {
			my $out = "%".-$size{$key}."s ";
			printf $out,$row->{$key};
		}
		print "\n";
	}

}


1;

