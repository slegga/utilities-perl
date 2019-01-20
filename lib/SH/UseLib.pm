package SH::UseLib;
use Mojo::Base -strict;
use FindBin;
use Mojo::File 'path';



sub import {
    my @tmp = @{path($INC{'SH/UseLib.pm'})->to_abs->to_array};
#    warn join '§',@tmp;
    splice(@tmp,$#tmp-3); #remove 3 dirs;

    my $git = path(@tmp);
#    warn $git;
    for my $dir($git->list({dir => 1})->each ) {
        my $lib = $dir->child('lib');
        if ( -e $lib ) {
            unshift @INC, $lib;
        }
    }
#    warn join("\n",@INC);
}

1;

__END__

=head1 NAME

SH::UseLib - Find all the lib catalog and put it in @INC

=head1 SYNOPSIS

 use lib '../../utilities-perl/lib';
 use SH::UseLib;

=head1 DESCRIPTION

Find all the lib catalog and put it in @INC

=head1 FUNTIONS

=head2 import

Called automatically with use SH::UseLib;

Put all the lib catalogs in @INC;

=cut
