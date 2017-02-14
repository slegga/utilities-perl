use Test::More;
use SH::Table;
use FindBin;
use File::Copy;
use strict;
use warnings;
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
#open my $stdin, '<', "2;SMALL;32\n";
sleep(1);
*STDIN = *DATA;
$test->newrow;

my $size = -s  "$FindBin::Bin/data/testing.csv";
#diag "Størrelse $size";
print"\n";
is($size,38,'Test 1');



done_testing;

__DATA__
2;SMALL;32

