use Test::More;
use Mojo::File 'path';
use SH::UseLib;
use SH::Email::ToHash;
use Mojo::Base -strict;
use utf8;

#		        t/data/email-quoted-print-problem.txt
my $raw = path('t/data/email-quoted-print-problem.txt');
my $email_h = SH::Email::ToHash->msgtext2hash($raw->slurp);
like($email_h->{body}->{content},qr'Steihamm', 'Got correct word');
$raw = path('t/data/problem-subj-utf8.txt');
$email_h = SH::Email::ToHash->msgtext2hash($raw->slurp);
like($email_h->{header}->{Subject},qr'Steihamm',
#     ;, Det er ikke nok bare å se gjennom profiler av singler. Kontakt dem nå!', 
     'Got correct Subject');

done_testing;
