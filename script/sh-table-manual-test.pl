#!/usr/bin/env perl
use FindBin;

use lib "$FindBin::Bin/../lib";
use SH::Table;

$SH::Table::directory = "$FindBin::Bin/../t/data";
my $empty = SH::Table->new('empty');
$empty->show;

my $test = SH::Table->new('testing');

$test->show;
$test->newrow();
$test->show;




