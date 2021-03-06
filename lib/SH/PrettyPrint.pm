package SH::PrettyPrint;
use Mojo::Base -strict;
use Carp;
use List::MoreUtils 'first_index';
use Data::Dumper;
use JSON;
use Clone  'clone';
use List::MoreUtils qw(first_index);
=head1 NAME

SH::PrettyPrint

=head1 SYNOPSIS

    use SH::PrettyPrint;
    print SH::PrettyPrint([['col1','col2'],['2col1','2col2']]);

=head1 DESCRIPTION

Pretty print. Collection of print data functions.

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
	my $options=shift;
	my @keys = sort keys %{$ahr->[0]};

	if (ref $options) {
	    if (exists $options->{columns}) {
	        my @t = @{$options->{columns} };
	        for my $t(@t) {
	            my $x = first_index {$t eq $_} @keys;
	            next if $x<0;
	            splice(@keys, $x, 1) or die "splice [".@keys."],$x,1";
	        }
	        unshift @keys,@t;
	    }
	}

	# Calculate size

	my %size;
	for my $key (@keys) {
		$size{$key} = length($key);
	}

	for my $row( @$ahr ) {
		for my $key (@keys) {
		    next if ! exists $row->{$key};
			if ($row->{$key} && $size{$key} < length( $row->{$key} )) {
				$size{$key} = length( $row->{$key});
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
    my $opts_new = clone $opts;
    $opts_new->{indent_text} //= "\t";
    my $return ='';
        if (! ref $opts) {
        return JSON->new->utf8->space_after->pretty(1)->encode($data_r);
    }
    my @path;
    if (ref $data_r eq 'HASH') {
        if (exists $opts->{order} && ref $opts->{order} eq 'ARRAY') {
    		$return = _req_value_hash($data_r,$opts_new,0);
            #            $key_tree = _req_key_hash($data_r,$opts_new);
        } else {
            ...;
        }
    } elsif(ref $data_r eq 'ARRAY') {
        ...;
    } else {
        ...;
    }
#	print Dumper $key_tree;
    # reqursive tra
    my $indent=0;
	return $return;
}

sub _req_value_hash {
	my ($data_r, $opts, $indent) = @_;
	$indent//=0;
	my $return='';
	my $i =-1;
	$return .= "{\n";
	$indent++;
	my $key_order = _req_key_order($data_r,$opts);
    for my $k(@$key_order) {
    	$return .= ",\n" if $i != -1;
    	$i++;

   		my $value = $data_r->{$k};
    	if (ref $k eq 'HASH') {
    		die "hash is not allowed in key tree";
    	} elsif (ref $k eq 'ARRAY' ) {
#    		$indent++;
    		if (@$k == 2) {
    			#This is a hash
	    		$return .= ($opts->{indent_text} x $indent) ."\"$k->[0]\": " ._req_value_hash($k->[1], $data_r->{$k->[0]},$opts,$indent);
	    	} elsif  (@$k == 3) {
	    		#This is an array
	    		$return .= ($opts->{indent_text} x $indent) ."\"$k->[0]\": " ._req_value_array($k->[2], $data_r->{$k->[0]},$opts, $indent);
	    	} else {
	    		die "error";
	    	}
    	} else {
            for (ref $value) {
        		if ($_ eq 'HASH') {
    	    		$return .= ($opts->{indent_text} x $indent) . "\"$k\": " . _req_value_hash($value, $opts,$indent);
    	    	} elsif ($_ eq 'ARRAY') {
    	    		$return .= ($opts->{indent_text} x $indent) . "\"$k\": " . _req_value_array($value, $opts,$indent);
                } elsif ($_ eq 'SCALAR') {
                    my $o = $$value;
                    if ($o == 1) {
                        $o = 'true';
                    } else {
                        $o = 'false';
                    }
                    $return .= ($opts->{indent_text} x $indent) . "\"$k\": " .$o;
    	    	} elsif ($_ eq '') {
        	 		$return .= ($opts->{indent_text} x $indent) . "\"$k\": \"$value\"";
    	    	} else {
                    ...;
                }
            }
    	}

    }

    $indent--;
    $return .= "\n".($opts->{indent_text} x $indent) . "}";
    return $return;
}

sub _req_value_array {
	my $data_r = shift;
	my $opts = shift;
	my $indent = shift;
	my $return="[\n";
	$indent++;
	my $f = 0;
	for my $i(@$data_r) {
		$return .= ",\n" if $f;
		if (ref $i eq '') {
			$return .= ($opts->{indent_text} x $indent) . "\"$i\"";
		} elsif(ref $i eq 'HASH') {
			$return .= ($opts->{indent_text} x $indent) . _req_value_hash($i,$opts,$indent);
		} elsif(ref $i eq 'ARRAY') {
			...;
		} else {
			die "Unknown type ".ref $i;
		}
		$f=1;
	}
	$indent--;
	$return.="\n".($opts->{indent_text} x $indent) . "]";
};

sub _req_key_order {
    my ($data_r,$opts,$indent) =@_;
    confess Dumper $data_r if ref $data_r ne 'HASH';
    my @keys = keys %$data_r;
    my @o = grep {defined} @{ $opts->{order} };
    my @out=();
    for my $i(@o) {
        my $plc = first_index { $_ eq $i } grep{$_} @keys;
        if ( $plc > -1 ) {
			my $key = splice(@keys, $plc, 1);
          	push @out, $key;
        }
    }
    for my $key (sort @keys) {
	    push @out, $key;
	}
	return  \@out;
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
