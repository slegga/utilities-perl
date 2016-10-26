 use Test::More tests => 2;
use Test::Script;
$ENV{CONFIG_DIR} = 't/etc';
 script_compiles('bin/backup.pl');
 script_runs(['bin/backup.pl', 'test.tc']);
