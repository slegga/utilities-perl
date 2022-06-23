use Mojo::Base -strict;
use Test::More;
use Test::Spell;
use open 'locale';

my $t= Test::Spell->new(file=> 't/txt/norsk-tekst.txt', language => 'nb_NO');
$t->test_text_spelling;
done_testing;