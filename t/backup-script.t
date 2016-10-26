use Test::More;
use Test::Script;
use FindBin;
$ENV{CONFIG_DIR} = 't/etc';
 script_compiles('bin/backup.pl');
 script_runs(['bin/backup.pl', 'test.tc']);
ok(-f "/tmp/backupdisk1/$FindBin::Bin/fromdir/test.txt",'File is copied');
`rm -rf /tmp/backupdisk1`;

ok(! -d '/tmp/backupdisk1','backup is deleted');
ok(-f $FindBin::Bin.'/fromdir/test.txt','Test that nothing from source is deleted');
done_testing();
