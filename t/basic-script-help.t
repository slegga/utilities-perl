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
	TESTING->new->with_options->arguments('--help')->main
}
done_testing;
