use Test::More;
use SH::Transform;
use Mojo::File qw'curfile path';
use Carp::Always;

{
    my $trans=SH::Transform->new();
    my $exportfile=path('t/temp/test.yaml');
    $exportfile->remove;
    $trans->transform({file=>'t/data/test.json'},{file=>$exportfile});
    ok(-e "$exportfile","Export file exists");
}

{
    my $trans = SH::Transform->new();
    my $exportfile=path('t/temp/test2.yaml');
    $exportfile->remove;
    $trans->transform({file=>'t/data/testdata.csv', sep_char => ";"},{file=>$exportfile});
    ok(-e "$exportfile","Export file exists");
}

{
    my $passcode = SH::PassCode->new;
    my $trans = SH::Transform->new();
    my @unittestfiles = $passcode->list('unittest');
    $_->delete for @unittestfiles;
    $trans->transform({file=>'t/data/testdata.csv', sep_char => ";"},{type => 'PassCode'});
    @unittestfiles = $passcode->list('unittest');
    # Får ikke til å virke bytte av dir: ok(@{$dir->list->each},"Export passcode files exists file exists in $dir");
    ok (@unittestfiles, 'unittest files exists.');
}

{
    my $trans = SH::Transform->new();
    my $exportfile=path('t/temp/test3.yaml');
    $exportfile->remove;
    $trans->transform({type=>'SQLiteTable',file=>'t/data/testdata.db', table=>'unittest'},{file=>$exportfile});
    ok(-s "$exportfile"> 20,"Export file contains data.");
}

done_testing;