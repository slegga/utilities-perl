use Test::More;
use SH::CSV;

my $csv = SH::CSV->new;

my $csvdata = $csv->read('t/data/testdata.csv',{sep_char=>','});
is_deeply($csvdata,[{
    url      => 'https://10.0.0.23',
    username => 'admin',
    password => 'admin',
    totp     => '',
    extra    => '',
    name     => '10.0.0.23',
    grouping => 'unittest',
    fav      => 0,
}, {
    url      => 'https://www.paypal.com',
    username => 'mr42@example.com',
    password => 'hemmelig',
    totp     => '',
    extra    => '',
    name     => 'paypal.com',
    grouping => 'unittest',
    fav      => 0,
}],'Data is as expected');

my $csvdata = $csv->read('t/data/lastpass.csv',{sep_char=>','});
is_deeply($csvdata,[{
    url      => 'https://www.paypal.com',
    username => 'mr42@example.com',
    password => 'hemmelig',
    totp     => '',
    extra    => 'Fluff text
remember to keep a secret',
    name     => 'paypal.com',
    grouping => 'unittest',
    fav      => 0,
}, {
    url      => 'http://uwish',
    username => '',
    password => '',
    totp     => '',
    extra    => "Når passordet har løpt ut så bytt på password.com og ikke password.org

I tilfelle DNS trøbbel
example.com 8.8.8.8",
    name     => 'Longtext',
    grouping => 'unittest',
    fav      => 0
}],'Data is as expected');


done_testing;