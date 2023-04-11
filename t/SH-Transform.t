use Test::More;
use SH::Transform;
use Mojo::File qw'curfile path';

my $trans=SH::Transform->new();
my $exportfile=path('t/temp/test.yaml');
$exportfile->remove;
$trans->transform->({import_file=>'t/data/test.json',export_file=>$exportfile});
ok(-e "$exportfile","Export file exists");

done_testing;