use Test::More;
use SH::Table;
use FindBin;

diag 'Tests empty file';
ok(1,"Tester test");
$SH::Table::directory = "$FindBin::Bin/data";
my $empty = SH::Table->new('empty');
# print $empty->show;
# ok($empty->show(),'Works');

diag 'Existing file';
my $test = SH::Table->new('testing');
# diag $test->show;
# my @text =  $test->show;

is( $test->control,0 ,'control = 0');



done_testing;
