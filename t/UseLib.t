use Test::More;
use Mojo::Base -strict;
use SH::UseLib;
use Test::ScriptX;
print($INC{"Test/ScriptX.pm"}, "\n");
#SH::UseLib::import();
ok(grep({/utilities/} @INC), 'Include works');
ok(1,'Dummy');
done_testing;