
## ~/.perlcriticrc
# severity = 5
# verbose = %f: [%p] %m at line %l, column %c (Severity %s).\n%d\n
use Test::More;
my $cfg = "$ENV{HOME}/.perlcriticrc";
ok(-f $cfg,'perlcritic link does not exists. Run env-setup.pl to fix.');
use Test::Perl::Critic (-profile => $cfg);
all_critic_ok();
done_testing;