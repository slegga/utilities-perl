use Test::More;
use SH::PrettyPrint;
use Mojo::Base -strict;
my $array =['a','b',['c','d']];
SH::PrettyPrint::_set_array_item($array,1,'e');
is_deeply($array,['a','e',['c','d']],'Array changer works');

#easy
my $to_json = {a => 'b'};
my $json = SH::PrettyPrint::data_to_json_pretty($to_json, {order =>['b'],indent_text=>' '});
my $fasit = <<EOL;
{
 "a": "b"
}
EOL
is ($json."\n",$fasit,'JSON easy');

#less easy
$to_json = {a => 'b',c => 'd'};
$json = SH::PrettyPrint::data_to_json_pretty($to_json, {order =>['c'],indent_text=>' '});
$fasit = <<EOL;
{
 "c": "d",
 "a": "b"
}
EOL
is ($json."\n",$fasit,'JSON e');

# medium
$to_json = {a => {e => 'f'},c => 'd'};
$json = SH::PrettyPrint::data_to_json_pretty($to_json, {order =>['c'],indent_text=>' '});
$fasit = <<EOL;
{
 "c": "d",
 "a": {
  "e": "f"
 }
}
EOL
is ($json."\n",$fasit,'JSON medium');

# easy array
$to_json = {a => ['e', 'f'],c => 'd'};
$json = SH::PrettyPrint::data_to_json_pretty($to_json, {order =>['c'],indent_text=>' '});#, {order =>['c']});
$fasit = <<EOL;
{
 "c": "d",
 "a": [
  "e",
  "f"
 ]
}
EOL
is ($json."\n",$fasit,'JSON array');

done_testing;
