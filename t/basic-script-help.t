# script_compile.t
use Test2::V0;
use Test::Script;
use Mojo::File 'path';
use FindBin;
use Carp::Always;
use lib "$FindBin::Bin/../bin";
use lib "$FindBin::Bin/../script";
no warnings 'redefine';
my $testscriptname = path($0)->basename;
for my $script (glob('script/*'),glob('bin/*')) { #$FindBin::Bin . '/../
    next if -d $script;
    next if ( $script !~ /\.pl$/ && $script !~ /^[^\.]+$/);
    $script= path $script;
    next if $script->slurp !~ /use SH\:\:ScriptX\;/;
#    script_runs(["$script", '--help']);
	my $pc = $script->slurp;
	$pc =~ s/^sub /no warnings 'redefine';sub /m;
    eval <<EOF or die "eval $! $@";
package TESTING;
no warnings 'redefine';
$pc
EOF
#	TESTING->import;
	print $script."\n";
	my $help;

	{
		open(my $oldout, ">&STDOUT")     or die "Can't dup STDOUT: $!";
		close STDOUT;
		open STDOUT, '>', \$help;
		TESTING->new(help=>1)->main;
		close STDOUT;
		open(STDOUT, ">&", $oldout) or die "Can't dup \$oldout: $!";
	}
	my $b = $script->basename;
	ok($help=~/$testscriptname/m, $b.' ok');
}

done_testing;
