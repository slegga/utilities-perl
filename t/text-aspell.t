use Test::More;

ok(1,'dummy');
eval {
    require Text::Aspell;
    Text::Aspell::import;
} or do {
    done_testing;
    exit;
};

use utf8;
my $speller = Text::Aspell->new;

die unless $speller;


# Set some options
$speller->set_option('lang','no');
$speller->set_option('sug-mode','fast');


# check a word

my $word='skole';
ok( $speller->check( $word ),"$word found");
$word='løpe';
ok( $speller->check( $word ),"$word found");


# lookup config options
my $language = $speller->get_option('lang');
print $speller->errstr unless defined $language;

# fetch a config item that is a list
my @sgml_extensions = $speller->get_option_as_list('sgml-extension');


# fetch the configuration keys and their default settings
my $options = $speller->fetch_option_keys;

# or dump config settings to STDOUT
$speller->print_config || $speller->errstr;

done_testing;