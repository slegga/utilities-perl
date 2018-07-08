package SH::PrettyPrint;
use Mojo::Base -strict;

sub print_arrays {
    my $aar =shift;
    #   die "Expect array ref this is ". ref $ahr if (ref $ahr ne 'ARRAY' );
    for my $r(@$aar) {
        say join("\t", @$r);
    }
}

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

