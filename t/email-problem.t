use Test::More;
use Mojo::File 'path';
use SH::UseLib;
use SH::Email::ToHash;
#		        t/data/email-quoted-print-problem.txt
my $raw = path('t/data/email-quoted-print-problem.txt');
my $email_h = SH::Email::ToHash->msgtext2hash($raw->slurp);
like($email_h->{body}->{content},qr'Steihamm', 'Got correct word');
done_testing;