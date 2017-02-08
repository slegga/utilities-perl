use Test::More;
use SH::Table;
use FindBin;
use File::Copy;

diag 'Tests empty file';
ok(1,"Tester test");
$SH::Table::directory = "$FindBin::Bin/data";
copy("$FindBin::Bin/Backup/testing.csv", "$FindBin::Bin/data/testing.csv");
my $empty = SH::Table->new('empty');
# stdout_is {$empty->show} '','No outut';

diag 'Existing file';
my $test = SH::Table->new('testing');
# diag $test->show;
# my @text =  $test->show;

is( $test->control,0 ,'control = 0');
#stdout_like {$test->show} qr'ID;NAME;FOOTSIZE','No outut';
open my $stdin, '<', "2;SMALL;32\n";
local *STDIN = $stdin;
$test->newrow;

my $size = -s  "$FindBin::Bin/data/testing.csv";
diag "Størrelse $size";
diag $test->show;

ok(1,'Test 1');



done_testing;
