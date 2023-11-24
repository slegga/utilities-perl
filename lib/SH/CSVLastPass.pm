package SH::CSVLastPass;
use Mojo::Base -base, -signatures;
use Data::Printer;


=head1 NAME

SH::CSVLastPass - Home made CSV to handle return in field

=head1 SYNOPSIS

    my $hashes = SH::CSVLastPass->new->read('file.csv',{sep_char=>','});

=head1 DESCRIPTION

Currently only reads a CSV file.

=head1 METHODS

=head2 read

    my $csv= SH::CSVLastPass->new;
    $csv->read('filename',{sep_char=>',',column_with_extra=>['column1']});

Read CSV file and return data.

=cut

sub read($self, $file, $args) {
    open my $fh, "<", $file or die "Could not open $file";
    my $first_line = 1;
    my @hashes = ();
    my @keys = ();
    my $x = $args->{sep_char}//',';
    my $quote_char = $args->{quote_char}//'"';
    my $inrow = 0;
    my $inquote = 0;
    my $wheretoputextracolumns = $args->{column_with_extra};
    while (my $l =<$fh>) {
        chomp($l);
        if ($l =~ /aliexpress/) {
            $DB::single = 2;
        }
        if ($inrow) {
            my $i = keys %{$hashes[-1]};
            $i -=1;
            if ($i >$#keys) {
                p $hashes[-1];
                p $l;
                die;
            }
            my @vals = split(/$x/, $l, -1);
            if (! @vals) {
                $hashes[-1]{$keys[$i]} .= ($hashes[-1]{$keys[$i]} ? "\n":"");
                next;
            }
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
                $inrow = 0;
            }
            else {
                say STDERR "Error dump start";
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
            if( $l !~/(?<!$quote_char)$quote_char$x/ ) {
                $hashes[-1]{$keys[$i]} .= $l."\n";
            } else {
                my $data;
                $DB::single = 2;
                ($data,$l) = split(/(?<!$quote_char)$quote_char$x/, $l, 2);
             #   my $prechar = $1;
             #   $data .= $prechar;

                # Handle "", in string
            #    if ($prechar eq $quote_char) { # undo quote end.

            #    }

                $hashes[-1]{$keys[$i]} .= $data;
                $i++;
                my @vals = split(/$x/,$l,-1);
                for my $j($i .. $#keys) {
                    $hashes[-1]{$keys[$j]} = $vals[$j-$i];
                }
                $inquote = 0;
            }

            next;
        }
        next if !$l;
        if ($first_line) {

            @keys = split(/$x/, $l);
            $first_line = 0;
            next;
        }

        if( index($l,$x.$quote_char)>=0 || substr($l,0,1) eq $quote_char ) {
            my $row = {};
            my $i = -1;
            if (index($l,$quote_char.$x)>=0) {
                my ($prerest, $rest);
                $rest = $l;
                my @vals;
                 if(index($l,$x.$quote_char)>=0) {
                    ($prerest, $rest) = split (/$x$quote_char/, $l,2);
                 }
                 else {
                    ($prerest, $rest) = split (/$quote_char/, $l,2);
                 }
                 # prerest = ABC ,"def",ghi
                if ($prerest) {
                    my @vals = split(/$x/, $prerest,-1);
                    for my $i(0 .. $#vals) {
                        $row->{$keys[$i]} = $vals[$i];
                    }
                    $i = $#vals;
                }

                 # quote = abc ,"DEF",ghi
                 my $quote;
                 ($quote, $rest) = split (/$quote_char$x/, $rest, 2);
                $i++;
                $row->{$keys[$i]} = $quote;

                 # rest = abc ,"def",GHI

                $i++;
                @vals = split(/$x/, $rest,-1);
                for my $j(0 .. $#vals) {
                    $row->{$keys[$i+$j]} = $vals[$j];
                }
                p $row;
                push @hashes, $row;
                $inquote =0;
                next;
            }
            else {
                $inquote = 1;
                my($rest,$data) = split(/$x?$quote_char/, $l,2);
                my $row = {};
                my @vals = split(/$x/, $rest,-1);
                for my $i(0 .. $#vals) {
                    $row->{$keys[$i]} = $vals[$i];
                }
                $row->{$keys[$#vals+1]} .= "$data\n";
                push @hashes, $row;
                next;
            }
        }

        my @vals = split(/$x/,$l);
        if (scalar @keys == scalar @vals) {
            my $row = {};
            for my $i(0 .. $#keys) {
                $row->{$keys[$i]} = $vals[$i];
            }
            push @hashes, $row;
        }
        elsif (scalar @keys < scalar @vals) {
            # to many separators. Need to look for escape
            p $l;
            my $extra = scalar @vals - scalar @keys;
            my $j = 0;
            if (! $wheretoputextracolumns) {
                p $l;
                die "To many columns do not know what to do";
            }
            my $row = {};
            for my $i (0 .. $#vals) {
                if ($keys[$j] ne $wheretoputextracolumns) {
                    $row->{$keys[$j]} = $vals[$i];
                }
                else {
                    $row->{$keys[$j]} .= $vals[$i];
                    if ($extra) {
                        next;
                    }
                    $extra--;
                }
                $j++;
            }
            push @hashes, $row;
            next;
        }
        elsif (scalar @keys > scalar @vals) {
            # multiline row
            p $l;
                $inrow = 1;
                my $row = {};
                for my $i(0 .. $#vals) {
                    $row->{$keys[$i]} = $vals[$i];
                }
                push @hashes, $row;
            next;
        }
    }
    return \@hashes;
}

1;