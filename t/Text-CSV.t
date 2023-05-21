use Test::More;
use Text::CSV qw( csv );

my $csv = Text::CSV->new({ sep_char => ";" });

my $csvdata = csv(in=>'t/data/testdata.csv', headers => "auto");
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

my $csvdata = csv(in=>'t/data/lastpass.csv', headers => "auto");
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
}],'Data is as expected');


done_testing;