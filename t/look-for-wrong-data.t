use Test::More;
use Mojo::Base -strict;
use Mojo::File 'path';
use FindBin;
if ($ENV{USER} =~ /t52/) {
	ok(1,'dummy');
} else {
	my $path = path("$FindBin::Bin/../../");
	my $files = $path->list_tree;

	for my $f ($files->each) {
	    next if $f=~/ggp\-base\/lib\/Jython/;
	    next if $f =~/look\-for\-wrong\-data\.t/;
	    ok($f!~/\/nx\-/,$f.' ok name');
	    my $cont = $f->slurp;
	    ok($cont!~/t52/m,$f.' ok t52');
	    ok($cont!~/[^i]nx\-/m,$f.' ok nx');
	    ok($cont!~/Nx\:\:/m,$f.' ok Nx');
	}
}
done_testing;
