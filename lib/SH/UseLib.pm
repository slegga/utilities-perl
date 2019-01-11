package SH::UseLib;
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
