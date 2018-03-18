use Test::More;
use Mojo::Base -strict;
use Mojo::File 'path';
use FindBin;
my $path = path("$FindBin::Bin/../../");
my $files = $path->list_tree;
for my $f ($files->each) {
    next if $f=~/ggp\-base\/lib\/Jython/;
    next if $f =~/look\-for\-wrong\-data\.t/;
    my $cont = $f->slurp;
    ok($cont!~/t52/,$f.' ok');
    ok($cont!~/nx\-m/,$f.' ok');
}

done_testing;
