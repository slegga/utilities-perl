use Test::More;
use SH::Transform;
use Mojo::File qw'curfile path';
useCarp::Always;

my $trans=SH::Transform->new();
my $exportfile=path('t/temp/test.yaml');
$exportfile->remove;
$trans->transform({file=>'t/data/test.json'},{file=>$exportfile});
ok(-e "$exportfile","Export file exists");

done_testing;