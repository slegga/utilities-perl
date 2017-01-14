use Test::More;
use SH::Table;
use FindBin;

ok(1,"Tester test");
$SH::Table::directory = "$FindBin::Bin/data";
my $tab = SH::Table->new('testing');
done_testing;
