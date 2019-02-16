package SH::PrettyPrint;
use Mojo::Base -strict;
use Carp;
use List::MoreUtils 'first_index';
use Data::Dumper;
use JSON;
use Clone  'clone';

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
			printf $out,($row->{$key}//'');
		}
		print "\n";
	}

}

=head2 data_to_json_pretty
Print pretty and in order.
Takes data as ref and options as $hash_ref
Options:
order =>[qw/keys order/]
sort => 0/1
indent =>{tab/space}

=cut

sub data_to_json_pretty {
    my $data_r = shift or die;
    my $opts = shift;
    my $key_tree =[]; #i.e ['key1','key2',['key3',['key4','key5']]
    if (! ref $opts) {
        return JSON->new->utf8->space_after->pretty(1)->encode($data_r);
    }
    my @path;
    if (ref $data_r eq 'HASH') {
        if (exists $opts->{order} && ref $opts->{order} eq 'ARRAY') {
            $key_tree = _req_key_hash($key_tree,[@path],$data_r,$opts);
        } else {
            ...;
        }
    } elsif(ref $data_r eq 'ARRAY') {
        ...;
    } else {
        ...;
    }

    # reqursive tra
    my $return ='';
    my $indent=0;
    for my $k(@$key_tree) {
    	if (ref $k eq 'HASH') {
    		die "hash is not allowed in key tree";
    	} elsif (ref $k eq 'ARRAY') {
#    		$return .= ' ' x $indent .$self->_key($k->[0]) . $self->_value($k->[1],$indent+1);
    		...;
    	} else {
    		$return .= "\"$k\": \"$data_r->{$k}\",\n";
    	}

    }
    return $return;
}

sub _req_key_hash {
    my ($key_tree,$path,$data_r,$opts) =@_;
    my @keys = keys %$data_r;
    my @o = grep {defined} @{ $opts->{order} };
    my @out=();
    for my $i(@o) {
        my $plc = first_index { $_ eq $i } grep{$_} @keys;
        if ( $plc > -1 ) {
            my $key = splice(@keys, $plc, 1);
            my $input;
            if (ref $data_r->{$key} eq 'HASH') {
                    my $value=[];
                    push @$path, $#out+1;
                    _req_key_hash($value, $path,$data_r->{$key},$opts);
                    pop @$path;
                    $input = [$key, $value];
            } elsif (ref $data_r->{$key} eq 'ARRAY') {
                my $value = $data_r->{$key};
                $input=[$key, undef, $value];
            } else {
                $input = $key;
            }
            push @out, $input;
        }
    }
    push @out, @keys;
    if (@$path) {
	    _set_array_item($key_tree, @$path,\@out);
	} else {
		$key_tree = \@out;
	}
	return $key_tree;
}

sub _set_array_item {
    my $array_ref = shift;
    my $value = pop;
    if (! defined $value )  {
        confess "To few values";
    }
    my @pointer = @_;

    if (@pointer > 10) {
    	print STDERR Dumper($array_ref);
    	print STDERR Dumper \@pointer;
    	print STDERR Dumper $value;
    	die;
    }
    if(@pointer ==0) {
#    	print STDERR Dumper($array_ref);
#    	print STDERR Dumper $value;
#        die "No poiter";
		$array_ref = clone $value;
    } elsif (@pointer ==1) {
        $array_ref->[$pointer[0]] = $value or die join(',',@pointer);
    } elsif (@pointer ==2) {
        $array_ref->[$pointer[0]][$pointer[1]] = $value;
    } elsif (@pointer ==3) {
        $array_ref->[$pointer[0]][$pointer[1]][$pointer[2]] = $value;
    } else {
        die "To many paramters no support";
    }

}

1;
