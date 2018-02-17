#!/usr/bin/env perl

use Test::More;
use strict;
use warnings;
use IPC::Run qw( run );

unlink('t/etc/file-forwarder.done.yml');
run( [ './bin/file-forwarder.pl', '--homedir', 't' ], \'', \my $out, \my $err );

print "out: $out\n";
print "err: $err\n";
# use FindBin;
# use strict;
# use warnings;
#
# {
#     local @ARGV = ("--homedir","t");
#     require "./bin/file-forwarder.pl";
# }
is($err,'','No errors');
ok(1,'Completed');
done_testing;
