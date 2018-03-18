package SH::ArrayCompare;
use Data::Dumper;
use strict;
use warnings;
use autodie;
use Carp;
use Scalar::Util qw/looks_like_number/;
use Exporter 'import';
our @EXPORT_OK =
    qw(compare_arrays compare_arrays_unsorted get_unmatched get_unmatched_unsorted data_query data_test_where data_select);

our $VERSION=0.43;
=encoding utf8

=head1 NAME

Nx::SQL::File.pm- A class for exporting/importing/comparing data between file/perl/db.

=head1 VERSION

0.01

=head1 SYNOPSIS

    use Data::Dumper;
    use Nx::SQL::ArrayCompare;

    $from = [
                {
                    'utsIdPrefiks' => 'DS',
                    'utsIdVerdi' => 'N01GGAAB'
                },
                {
                    'utsIdPrefiks' => 'IP',
                    'utsIdVerdi' => '172.29.142.58'
                }
                ];
    $iterate = ['@'];
    $input ={where => {'utsIdPrefiks' => 'IP'},
            select => [['utsIdVerdi']]};

    # {'utsIdPrefiks' => qr/^IP$/} is also valid

    print Dumper Nx::SQL::ArrayCompare::data_query($from,$iterate,$input);

    #$VAR1 = [
    #          {
    #            'utsIdVerdi' => '172.29.142.58'
    #          }
    #        ];

    print  Nx::SQL::ArrayCompare::data_select($from,[0,'utsIdVerdi']),"\n\n"

    # N01GGAAB

=head1 DESCRIPTION

A package mainly for common subroutines for the nx-staticdata toolkit.
Contains methods for table data from

=head1 METHODS


=head2 compare_arrays

    set theory: calculates A\B,A/\B,B/A
    input: sorttype('n'umeric,'a'lphanumeric), A_arrref, B_arrref
    return three arrayrefs:
    arrayref of elements in arrayA that does not exists in arrayB.
    arrayref of elements arrayA section arrayB.
    arrayref of elements in arrayB that does not exists in arrayA.

    Both arrays must be sorted either alphanumeric or numeric ascending according to sorttype

=cut

sub compare_arrays ($$$) {
    my $sorttype = shift;
    confess( "Invalid sorttype %s", $sorttype ) if ( $sorttype !~ /^[n|a]$/ );
    my $A_arrref = shift;
    my $B_arrref = shift;
    confess( "Extra arguments %s", join( ', ', @_ ) ) if (@_);
    if ( !defined $A_arrref || !defined $B_arrref ) {
        confess("Not defined ");
    }
    confess( "not an array %s", ref $A_arrref ) if ( ref $A_arrref !~ /ARRAY/ );
    my $cA = 0;
    my $cB = 0;
    my $cmp;
    my $maxarrA = scalar @$A_arrref;
    my $maxarrB = scalar @$B_arrref;
    my ( $prevA, $prevB );

    if ( $sorttype eq 'n' ) {
        ( $prevA, $prevB ) = ( -999999999, -999999999 );
    } else {
        ( $prevA, $prevB ) = ( "", "" );
    }
    my ( @exA, @exAB, @exB );
    while ( $cA < $maxarrA && $cB < $maxarrB ) {
        if ( $sorttype eq 'n' ) {
            $cmp = $$A_arrref[$cA] <=> $$B_arrref[$cB];
            if ( $prevA > $$A_arrref[$cA] || $prevB > $$B_arrref[$cB] ) {
                confess("Matched lists are not sorted numeric ascending");
            }
        } else {
            $cmp = $$A_arrref[$cA] cmp $$B_arrref[$cB];
            if (   !defined $$A_arrref[$cA]
                || !defined $$B_arrref[$cB]
                || $prevA gt $$A_arrref[$cA]
                || $prevB gt $$B_arrref[$cB] )
            {
                confess( "Matched lists are not sorted aphanumeric ascending %s %s %s %s",
                    $$A_arrref[$cA], $$B_arrref[$cB], $cA, $cB );
            }
        }
        my $prevA = $$A_arrref[$cA];    #for detecting unsorted data
        my $prevB = $$B_arrref[$cB];    #for detecting unsorted data
        if ( $cmp == 1 ) {
            push( @exB, $$B_arrref[$cB] ) if $$B_arrref[$cB];
            $cB++;
        } elsif ( $cmp == 0 ) {
            push( @exAB, $$A_arrref[$cA] ) if $$A_arrref[$cA];
            $cA++;
            $cB++;
        } elsif ( $cmp == -1 ) {
            push( @exA, $$A_arrref[$cA] ) if $$A_arrref[$cA];
            $cA++;
        } else {
            warn( "COMPARE ERROR %s", $cmp );
        }
    }

    #ADD REST
    if ( ( defined $$A_arrref[$cA] ) && !defined $$B_arrref[$cB] ) {
        while ( $cA < $maxarrA ) {
            push( @exA, $$A_arrref[$cA] );
            $cA++;
        }
    }
    if ( ( !defined $$A_arrref[$cA] ) && defined $$B_arrref[$cB] ) {
        while ( $cB < $maxarrB ) {
            push( @exB, $$B_arrref[$cB] );
            $cB++;
        }
    }
    \@exA, \@exAB, \@exB;
}

=head2 compare_arrays_unsorted

    set theory: calculates A\B,A/\B,B/A
    input: A_arrref, B_arrref
    return three arrayrefs:
    arrayref of elements in arrayA that does not exists in arrayB.
    arrayref of elements arrayA section arrayB.
    arrayref of elements in arrayB that does not exists in arrayA.

    slower than compare_arrays

    OBS!
    THIS IS LIKE FILE DIFF! The order of items in array matters!

    For making it like a real array diff where order has no meaning
    you have to sort in front of compare_arrays

    Or design a new method similar like this one but adding
    use [AB]temporar_offset
    variable to remember already compared values.

=cut

sub compare_arrays_unsorted ($$) {
    my $A_arrref = shift;
    my $B_arrref = shift;
    confess "INPUT ERROR: Arguments are not array refs $A_arrref $B_arrref"
        if !( ref $A_arrref eq 'ARRAY' && ref $B_arrref eq 'ARRAY' );
    confess( "Extra arguments %s", join( ', ', @_ ) ) if (@_);
    if ( !defined $A_arrref || !defined $B_arrref ) {
        confess("Not defined ");
    }
    confess( "not an array %s", ref $A_arrref ) if ( ref $A_arrref !~ /ARRAY/ );
    my $cA      = 0;
    my $cB      = 0;
    my $cC      = 0;                   #diff offset
    my $maxarrA = scalar @$A_arrref;
    my $maxarrB = scalar @$B_arrref;
    my ( @exA, @exAB, @exB );

    while ( $cA < $maxarrA && $cB < $maxarrB ) {
        if ( $$A_arrref[$cA] eq $$B_arrref[$cB] ) {
            push( @exAB, $$A_arrref[$cA] ) if $$A_arrref[$cA];
            $cA++;
            $cB++;
        } elsif ( $cA + $cC == $maxarrA || $cB + $cC == $maxarrB ) {
            push( @exA, $$A_arrref[$cA] );
            push( @exB, $$B_arrref[$cB] );
            $cA++;
            $cB++;
            $cC = 0;
        } elsif ( $cC > 0 && $$A_arrref[ $cA + $cC ] eq $$B_arrref[$cB] ) {

            #            my $dummy=$cA+$cC- 1;
            #this didn't work            push( @exA, $$A_arrref[$cA .. $dummy] );
            for ( my $i = $cA; $i <= ( $cA + $cC - 1 ); $i++ ) {
                $exA[ ++$#exA ] = $$A_arrref[$i];
            }
            push( @exAB, $$B_arrref[$cB] );
            $cA += $cC + 1;
            $cB++;
            $cC = 0;
        } elsif ( $cC > 0 && $$A_arrref[$cA] eq $$B_arrref[ $cB + $cC ] ) {

            #            my $dummy=$cB+$cC- 1;
            push( @exAB, $$A_arrref[$cA] );

            #this didn't work                        push( @exB, $$B_arrref[$cB .. $dummy] );
            for ( my $i = $cB; $i <= ( $cB + $cC - 1 ); $i++ ) {
                $exB[ ++$#exB ] = $$B_arrref[$i];
            }
            $cA++;
            $cB += $cC + 1;
            $cC = 0;
        } else {
            $cC++;
        }
    }

    #ADD REST
    if ( ( defined $$A_arrref[$cA] ) && !defined $$B_arrref[$cB] ) {
        while ( $cA < $maxarrA ) {
            push( @exA, $$A_arrref[$cA] );
            $cA++;
        }
    }
    if ( ( !defined $$A_arrref[$cA] ) && defined $$B_arrref[$cB] ) {
        while ( $cB < $maxarrB ) {
            push( @exB, $$B_arrref[$cB] );
            $cB++;
        }
    }
    \@exA, \@exAB, \@exB;
}

=head2 get_unmatched

    set theory: calculates A\B (fast)
    input: sorttype('n'umeric,'a'lphanumeric), A_arrref, B_arrref
    return array of elements in arrayA that does not exists in arrayB.
    Both arrays must be sorted either alphanumeric or numeric ascending according to sorttype

    This subroutine is written for fast execution for huge arrays.

=cut

sub get_unmatched($$$) {
    my $sorttype = shift;
    croak("Invalid sorttype '$sorttype' expect n|a") if ( $sorttype !~ /^[n|a]$/ );
    my ( $A_arrref, $B_arrref ) = @_;

    croak("\$A_arrref is undef") if ( !defined $A_arrref );
    croak("\$B_arrref is undef") if ( !defined $B_arrref );
    croak( "One or both of inputparameters is not an arrayref %s %s", ref($A_arrref), ref($B_arrref) )
        if ( ref($A_arrref) ne 'ARRAY' && ref($B_arrref) ne 'ARRAY' );

    return @$A_arrref if !scalar @$B_arrref;

    my $cA = 0;
    my $cB = 0;
    my $cmp;
    my ( $prevA, $prevB );

    if ( $sorttype eq 'n' ) {
        ( $prevA, $prevB ) = ( -999999999, -999999999 );
    } else {
        ( $prevA, $prevB ) = ( "", "" );
    }
    my @return;

    while ( $cA <= $#$A_arrref && $cB <= $#$B_arrref ) {
        if ( $sorttype eq 'n' ) {
            $cmp = $$A_arrref[$cA] <=> $$B_arrref[$cB];
            if ( $prevA > $$A_arrref[$cA] || $prevB > $$B_arrref[$cB] ) {
                confess("Unmatched lists are not sorted numeric ascending");
            }
        } else {
            $cmp = $$A_arrref[$cA] cmp $$B_arrref[$cB];
            if (   !defined $$A_arrref[$cA]
                || !defined $$B_arrref[$cB]
                || $prevA gt $$A_arrref[$cA]
                || $prevB gt $$B_arrref[$cB] )
            {
                confess( "Unmatched lists are not sorted aphanumeric ascending ",
                    $$A_arrref[$cA], " ", $$B_arrref[$cB], " ", $cA, " ", $cB );
            }
        }
        my $prevA = $$A_arrref[$cA];    #for detecting unsorted data
        my $prevB = $$A_arrref[$cB];    #for detecting unsorted data
        if ( $cmp == 1 ) {
            $cB++;
        } elsif ( $cmp == 0 ) {
            $cA++;
            $cB++;
        } elsif ( $cmp == -1 ) {
            push( @return, $$A_arrref[$cA] );
            $cA++;
        } else {
            confess( "COMPARE ERROR %s", $cmp );
        }
    }
    @return;
}

=head2 get_unmatched_unsorted

    same as Nx::SQL::Base->get_unmatched
    but much slower and keep position in A
    set theory: calculates A\B
    input: A_arrref, B_arrref
    return array of elements in arrayA that does not exists in arrayB.

=cut

sub get_unmatched_unsorted ($$) {
    my $A_arrref = shift;
    my $B_arrref = shift;
    confess( "Extra arguments %s", join( ', ', @_ ) ) if (@_);
    croak("\$A_arrref is undef") if ( !defined $A_arrref );
    croak("\$B_arrref is undef") if ( !defined $B_arrref );
    my $cA = 0;
    my $cB = 0;
    my @return;

    for $cA ( 0 .. $#$A_arrref ) {
        my $equal = 0;
        for $cB ( 0 .. $#$B_arrref ) {
            if ( $$A_arrref[$cA] eq $$B_arrref[$cB] ) {
                $equal = 1;
                last;
            }
        }
        push( @return, $$A_arrref[$cA] ) if ( $equal == 0 );
    }
    return @return;
}

=head2 data_test_where

arg1: ref to complex data structure
arg2: ref to complex data structure which is matched against arg1. Regex is ok to use as a value in the complex data structure
Returns 1 matching ok
Returns 0 if one or more criteria in arg2 is violated

Method created for searching for items in a list of json test.

=cut

sub data_test_where {
    die "Wrong number of input parameters" if !( @_ == 2 );
    my ( $data, $where ) = @_;
    die "Where is undef" if !defined $where;
    die "Where is not complex data type" if !ref $where;
    if ( ref $data eq 'HASH' ) {
        for my $k ( keys %$where ) {
            confess( "INTERNAL ERROR: $where", Dumper $where) if !defined $k;
            if ( !exists $data->{$k} ) {
                warn "! exists $k\n", Dumper $where, "\n", $data;
                return 0;
            }
            next if ( $data->{$k} eq $where->{$k} );
            if ( $where->{$k} =~ /^\(\?/ && $data->{$k} =~ $where->{$k} ) {

                #                warn "OK",$data->{$k},"=\~",$where->{$k};
                next;
            }
            if ( ref $where->{$k} eq 'HASH' ) {    #hash or array ref
                next if ( data_test_where( $data->{$k}, $where->{$k} ) );
                return 0;
            }

            #            warn ($data->{$k}//'[undef]'," ne ",$where->{$k}//'[undef]'," $k\n ");
            return 0;
        }
    } elsif ( ref $data eq 'ARRAY' ) {    #any many to many match
        confess( "INTERNAL ERROR: $where", Dumper $where) if ref $where ne 'ARRAY';
    WHERE:
        for my $wi ( 0 .. $#$where ) {
            for my $di ( 0 .. $#$data ) {
                last WHERE if ( $data->[$di] eq $where->[$wi] );
                if ( $where->[$wi] =~ /^\(\?/ && $data->[$di] =~ $where->[$wi] ) {

                    #                warn "OK",$data->{$k},"=\~",$where->{$k};
                    last WHERE;
                }
                if ( ref $where->[$di] ) {    #hash or array ref
                    last WHERE if ( data_test_where( $data->[$di], $where->[$wi] ) );
                    return 0;
                }

                #            warn ($data->{$k}//'[undef]'," ne ",$where->{$k}//'[undef]'," $k\n ");
                return 0;
            }
        }
    } else {
        die "Not handeled: ", ref $data, Dumper $data;
    }

    return 1;
}

=head2 data_query

SQL-SELECT inspired method to get data from a json like complex data structure

$_[0]: ref to full complex datastructure (FROM)
$_[1]: array ref of keys to iterate over. (defines what a ROW is)
$_[2]{ where: An hash ref Validates ROW like a where statement. Optional arg. See data_test_where method
$_[2] select}: An ref to array of arrays which defines what is going to be returned. If not defined a * kind of behavior.
Returns a reference to a complex datastructure

Have a look

See also Nx::Utils::PerlDataFind->data_find

=cut

sub data_query {
    my ( $from, $iterate, $input_hr ) = @_;
    my ( $where, $select );
    if ( defined $input_hr ) {
        if ( exists $input_hr->{where} ) {
            $where = $input_hr->{where} || confess("missing where");
        }
        if ( exists $input_hr->{'select'} ) {
            $select = $input_hr->{'select'} || confess("missing where");
        }
    }
    return _datawalk( $from, $iterate, 0, [], $where, $select );
}

sub _datawalk {
    my ( $from, $iterate, $keyno, $return, $where, $select ) = @_;
    return $return if ( $keyno - 1 ) > $#$iterate;
    if ( ( $keyno - 1 ) == $#$iterate ) {
        if ( defined $where ) {
            return $return if !data_test_where( $from, $where );
        }
        my $retvalue = {};
        if ( !defined $select || ref $select ne 'ARRAY' ) {
            $retvalue = $from;
        } else {
            for my $v (@$select) {
                my $key = join( '::', @$v );
                $retvalue->{$key} = data_select( $from, $v );
            }
        }

        #        warn @keysa, Dumper $retvalue,"\n\n";
        push @$return, $retvalue;
    } elsif ( ref $from eq 'HASH' ) {
        while ( my ( $k, $v ) = each %$from ) {

            #warn "$#@keysa <= $#$iterate && $k ne $iterate->[scalar @@keysa]\n";
            next if ( ( $keyno - 1 ) < $#$iterate && $k ne $iterate->[$keyno] );

            # Keep track of the hierarchy of keys, in case
            # our callback needs it.
            $keyno++;

            if ( ref($v) eq 'HASH' || ref($v) eq 'ARRAY' ) {
                $return = _datawalk( $v, $iterate, $keyno, $return, $where, $select );
            }
            $keyno--;
        }
    } elsif ( ref $from eq 'ARRAY' ) {
        for my $k ( 0 .. scalar @$from ) {
            my $v = $from->[$k];
            $keyno++;
            if ( ref($v) eq 'HASH' || ref($v) eq 'ARRAY' ) {
                $return = _datawalk( $v, $iterate, $keyno, $return, $where, $select );
            }
            $keyno--;
        }
    }
    return $return;
}

=head2 data_select

$_[0]: a ref to a complex data structure
$_[1]: a array ref with keys to an items

Return an item from a complex data structure reference.

Sub exists cause of using an array ref(with unknown number of 'step') to locate item

See L<SYNOPSIS> for example

=cut

sub data_select {
    my $data     = shift;
    my $key_list = shift;
    return $data if !defined $key_list;
    return $data if !@$key_list;
    my @keysa = @$key_list;
    if ( ref $data eq 'HASH' ) {
        my $firstkey = shift @keysa;
        confess( "return data missing key: " . $firstkey . " possible keys:" . join( ',', keys %$data ) )
            if !exists $data->{$firstkey};
        my $senddata = $data->{$firstkey};
        confess( "senddata is undef ", $firstkey // '[undef]', Dumper @keysa, $data ) if !defined $senddata;
        return data_select( $data->{$firstkey}, \@keysa );
    } elsif ( ref $data eq 'ARRAY' ) {
        my $firstkey = shift @keysa;
        confess( "Expect a number got '" . $firstkey . "'" ) if !looks_like_number($firstkey);
        return data_select( $data->[$firstkey], \@keysa );

    }
    die "Internal ERROR: Do not know how to handle\n", Dumper $data, "\n\n", @keysa;
}


1;
