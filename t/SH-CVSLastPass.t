use Test::More;
use SH::CSVLastPass;

my $csv = SH::CSVLastPass->new;

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
},{
    url      => "https://id.circlekeurope.com/customer/#/registerUserStepTwo/?redirect=%7B%22name%22:%22main.authorizeApp%22,%22params%22:%7B%22clientId%22:%220852548c-20db-38be-8611-c85d160f0722%22,%22scope%22:%22USER%22,%22state%22:null,%22redirectUrl%22:null%7D%7D&ui_customization=extra2",
    username => 'user@example.com',
    password => 'secret',
        totp     => '',
    extra    => '',
    name     => 'circlekeurope.com',
    grouping => 'unittest',
    fav      => 0
}
,{
    url      => "http://sn",
    username => '',
    password => '',
        totp     => '',
    extra    => 'NoteType:Address
Title:
First Name:John
Middle Name:
Last Name:Doe
Username:
Gender:
Birthday:
Company:
Address 1:Street road 1
Address 2:
Address 3:
City / Town:Heaven
County:
State:
Zip / Postal Code:12345
Country:US
Timezone:
Email Address:
Phone:{""num"":"""",""cc3l"":"""",""ext"":""""}
Evening Phone:
Mobile Phone:
Fax:',
    name     => 'John Doe',
    grouping => 'unittest',
    fav      => 0
}
],'Data is as expected2');


done_testing;