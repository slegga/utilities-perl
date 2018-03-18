use Test::More;
use Mojo::Base -strict;

use SH::ArrayCompare;

is_deeply([ SH::ArrayCompare::compare_arrays('a', ['a','b'], ['b','c']) ]
    ,[['a'],['b'],['c']],'works');
done_testing;
