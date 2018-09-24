# script_compile.t
use Test2::V0;
use Test::Script;
use Mojo::File 'path';
use FindBin;
use lib "$FindBin::Bin/../bin";
use lib "$FindBin::Bin/../script";
no warnings 'redefine';
for my $script (glob('script/*'),glob('bin/*')) { #$FindBin::Bin . '/../
    next if -d $script;
    next if ( $script !~ /\.pl$/ && $script !~ /^[^\.]+$/);
    $script= path $script;
    next if $script->slurp !~ /use SH\:\:ScriptX\;/;
#    script_runs(["$script", '--help']);
	my $pc = $script->slurp;
    eval <<EOF or die "eval $! $@";
package TESTING;
$pc
EOF
#	TESTING->import;
	print $script."\n";
	open(my $oldout, ">&STDOUT")     or die "Can't dup STDOUT: $!";
	close STDOUT;
	my $help;
	open STDOUT, '>', \$help;
	TESTING->new(help=>1)->with_options->main;
	close STDOUT;
	open(STDOUT, ">&", $oldout) or die "Can't dup \$oldout: $!";
	warn $help;
	my $b = $script->basename;
	ok($help=~/$b/m, $b.' ok');
}

done_testing;
