use Test::More;
use Mojo::Base -strict;
use SH::UseLib;
#SH::UseLib::import();
ok(grep({/utilities/} @INC), 'Include works');
ok(1,'Dummy');
done_testing;