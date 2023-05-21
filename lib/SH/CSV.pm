package SH::CSV;
use Mojo::Base -base, -signatures;
use Data::Printer;


=head1 NAME

SH::CSV - Home made CSV to handle return in field

=head1 SYNOPSIS

    my $hashes = SH::CSV->new->read('file.csv',{sep_char=>','});

=head1 DESCRIPTION

Currently only reads a CSV file.

=head1 METHODS

=head2 read

    my $csv= SH::CSV->new;
    $csv->read('filename',{sep_char=>',',column_with_extra=>['column1']});

Read CSV file and return data.

=cut

sub read($self, $file, $args) {
    open my $fh, "<", $file or die "Could not open $file";
    my $first_line=1;
    my @hashes=();
    my @keys=();
    my $x = $args->{sep_char}//',';
    my $quote_char = $args->{quote_char}//'"';
    my $inrow=0;
    my $inquote=0;
    my $wheretoputextracolumns=$args->{column_with_extra};
    while (my $l =<$fh>) {
        chomp($l);
        if ($inrow) {
            my $i = keys %{$hashes[-1]};
            $i -=1;
            if ($i >$#keys) {
                p $hashes[-1];
                p $l;
                die;
            }
            my @vals = split(/$x/, $l);
            $hashes[-1]{$keys[$i]} .= ($hashes[-1]{$keys[$i]} ? "\n":"") . $vals[0];
            if (@vals == 1) {
                next;
            }
            for my $j(1 .. $#vals) {
                if (! $keys[$i+$j]) {
                    say "$i+$j: '$vals[$j]'";
                    say $l;
                    p $hashes[-1];
                    ...;
                }
                $hashes[-1]{$keys[$i+$j]} = $vals[$j];
            }
#            p $hashes[-1];
#            ...; # setningen under må fikses slik at det blir rett.
            if (keys %{$hashes[-1]} == @keys) {
                $inrow=0;
            }
            else {
                p $hashes[-1];
                p @vals;
                say "line: $l";
                die "Keys: ".join('-',keys %{$hashes[-1]})." == " .join('-',@keys);
            }
            next;
        }
        if ($inquote) {
            my $i = keys %{$hashes[-1]};
            $i -=1;
            if ($i >$#keys) {
                p $hashes[-1];
                p $l;
                die;
            }
            if(index($l, $quote_char.$x) == -1) {
                $hashes[-1]{$keys[$i]} .= $l."\n";
            } else {
                $DB::single=2;
                my $data;
                ($data,$l) = split(/$quote_char$x/, $l, 2);
                $hashes[-1]{$keys[$i]} .= $data;
                $i++;
                my @vals = split(/$x/,$l);
                for my $j($i .. $#keys) {
                    $hashes[-1]{$keys[$j]} = $vals[$j-$i];
                }
                $inquote=0;
            }
            
            next;
        }
        next if !$l;
        if ($first_line) {

            @keys = split(/$x/, $l);
            $first_line=0;
            next;
        }
        my @vals = split(/$x/,$l);
        if (scalar @keys == scalar @vals) {
            my $row={};
            for my $i(0 .. $#keys) {
                $row->{$keys[$i]} = $vals[$i];
            }
            push @hashes, $row;
        }
        elsif (scalar @keys < scalar @vals) {
            # to many separators. Need to look for escape
            p $l;
            my $extra = scalar @vals - scalar @keys;
            my $j=0;
            if (! $wheretoputextracolumns) {
                p $l;
                die "To many columns do not know what to do";
            }
            for my $i (0 .. $#vals) {
                if ($keys[$j] ne $wheretoputextracolumns) {
                    $keys[$j]=$vals[$i];
                }
                else {
                    $keys[$j].=$vals[$i];
                    $extra--;
                    if (!$extra) {
                        next;
                    }
                }
                $j++;
            }
        }
        elsif (scalar @keys > scalar @vals) {
            # multiline row
            p $l;
            if( index($l,$x.$quote_char)>=0 ) {
                if (index($l,$quote_char.$x)>=0) {
                    say "No support for quote on same line yet";
                    ...;
                }
                $inquote=1;
                #my($l,$data) = split(/$x.$quote_char/, $l,2);
                my $row = {};
                $DB::single=2;
                @vals = split(/$x/, $l);
                for my $i(0 .. $#vals) {
                    if ($i == $#vals) {
                        $vals[$i] = substr($vals[$i],1);
                    }
                    $row->{$keys[$i]} = $vals[$i];
                }
                $row->{$keys[$#vals]} .= "\n";
                push @hashes, $row;
            } else {
                $inrow=1;
                my $row = {};
                for my $i(0 .. $#vals) {
                    $row->{$keys[$i]} = $vals[$i];
                }
                push @hashes, $row;
            }
            next;
        }
    }
    return \@hashes;
}

1;