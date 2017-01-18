use Test::More;
use SH::Table;
use FindBin;

diag 'Tests empty file';
ok(1,"Tester test");
$SH::Table::directory = "$FindBin::Bin/data";
my $tab = SH::Table->new('empty');






done_testing;
