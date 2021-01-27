package SH::UseLib;
use Mojo::Base -strict;
use Mojo::File;

#our @INC;

sub import {
    my @tmp = @{Mojo::File::path($INC{'SH/UseLib.pm'})->to_abs->to_array};
#    warn join '§',@tmp;
    splice(@tmp,$#tmp-3); #remove 3 dirs;

    my $git = Mojo::File::path(@tmp);
 #   warn $git;
    for my $dir($git->list({dir => 1})->each ) {
        my $lib = $dir->child('lib');
        if ( -d $lib ) {
            push @INC, "$lib"; #must not use unshift. Get a strange errormessage.
        }
    }
#    warn join("\n",@INC);
}

1;

__END__

=head1 NAME

SH::UseLib - Find all the lib catalog and put it in @INC

=head1 SYNOPSIS

 use lib 'lib';
 use Mojo::File 'path';
 my $lib;
 BEGIN {
    my $gitdir = Mojo::File->curfile;
    my @cats = @$gitdir;
    while (my $cd = pop @cats) {
        if ($cd eq 'git') {
            $gitdir = path(@cats,'git');
            last;
        }
    }
    $lib =  $gitdir->child('utilities-perl','lib')->to_string; #return utilities-perl/lib
 };
 use lib $lib;
 use SH::UseLib;
 use Model::GetCommonConfig;

=head1 DESCRIPTION

Find all the lib catalog and put it in @INC

=head1 FUNCTIONS

=head2 import

Called automatically with use SH::UseLib;

Put all the lib catalogs in @INC;

=cut
