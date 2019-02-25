package Test::ScriptX;
use Mojo::Base -base;
use Test::More();

use Mojo::Util qw(decode encode);
use FindBin;
use Mojo::File 'path';
use Capture::Tiny ':all';

=head1 NAME

Test::ScriptX - Test module for script based on SH::ScriptX

=head1 SYNOPSIS

 use Test::ScriptX;
 use Mock::Quickly;
 my $mock = Mock::Quickly->new;
 {
     my $t = Test::ScriptX->new('bin/script-to-be-tested.pl','main', email_obj=>$mock);
     $t->run(help=>1)->stderr_ok()->stdout_like( qr{basename(0)} );
 }

=head1 DESCRIPTION

Test module created after the spirit of Test::Mojo

THe greatest benefit of using SH::Script is the easy way to test script.

Also support script with->roles. Look for string '__PACKAGE__->with_roles(...)' where ... is a list of strings.

=head1 ATTRIBUTES

=head2 testobject

Place to store the script object which is tested.

=cut

has testobject        => sub {{}};
has cached_stdout     => '';
has cached_stderr     => '';
has cached_return     => '';
has scriptname        => '';
has main_sub          => 'main';
has attributes        => sub{{}};
has success           => '';
has 'roles';

=head1 METHODS

=head2 new

 First argument is script name location
 The rest if any is key => value of default option and script variables.
 main_sub key set another main sub than main.

=head3 Synopsis

my $t = Test::ScriptX->new('bin/script-to-be-tested.pl',main_sub=>'app', email_obj=>$mock);

=cut

sub new {
    my ($class, $scriptname) = (shift,shift);
    $scriptname = path($scriptname);
    my $attributes={};
    $attributes = {@_} if (@_);
    my $self = $class->SUPER::new( scriptname => $scriptname, attributes => $attributes );

#    $self->scriptname(path shift);
#    $self->attributes(\%{@_}); # convert to hash_ref
    my $pc = $self->scriptname->slurp;
    die $self->scriptname . " does not use ::ScriptX" if ($pc !~ /use \w\w\:\:ScriptX\;/);
#    script_runs(["$script", '--help']);
    $pc =~ s/^sub /no warnings 'redefine';sub /m;
    eval <<EOF or die "eval ".($@||$self->scriptname .' do not return true. Set __PACKAGE__->new->main as the last statment in script');##no critic
package SCRIPTX::TESTING;
no warnings 'redefine';
$pc
EOF
    #SCRIPTX::TESTING->import;
    if ($pc =~/\_\_PACKAGE\_\_\-\>with\_roles\(([^\)]+)/) {
        $self->roles( [ eval $1 ] );##no critic
    }

    return $self->_test('is',$@,'',"eval of object " .$self->scriptname );
}

=head2 run

Run script object with given key => value input.
Store stdout and stderr out put and retrun value if any.


=cut

sub run {
    my  $self = shift;
	{
        my $mainsub = $self->main_sub;

        my %data =();
        %data = @_ if  @_;
        my %attr = %{$self->attributes};
        %attr = (%attr,%data);
        #$self->testobject()
        my ($stdout, $stderr, @result) = capture {
            my $class;
        	if (! $self->roles ) {
	            SCRIPTX::TESTING->new(%attr)->$mainsub;
	        } else {
	        	SCRIPTX::TESTING->with_roles(@{ $self->roles })->new(%attr)->$mainsub;
	        }
        };
        $self->cached_stdout($stdout);
        $self->cached_stderr($stderr);
        $self->cached_return(join("\n",map{ defined } @result)) if @result;
    }
    return $self;
		# open(my $oldout, ">&STDOUT")     or die "Can't dup STDOUT: $!";
		# close STDOUT;
		# open STDOUT, '>', \$help;
		# TESTING->new(%{ $self->attributes })->$mainsub;
		# close STDOUT;
		# open(STDOUT, ">&", $oldout) or die "Can't dup \$oldout: $!";
}

=head2 stderr_ok

Check that script does not write to stderr

=cut

sub stderr_ok {
    my ($self,$desc) = @_;
    #	my $b = $script->basename;
    #	ok($help=~/$testscriptname/m, $b.' ok');

    return $self->_test('is',$self->cached_stderr,'');
}

=head2 stderr_like

Check that script does not write to stderr

=cut

sub stderr_like {
    my ($self, $regex, $desc) = @_;
    return $self->_test('like', $self->cached_stderr,
      $regex, _desc($desc, qq{stdout like "$regex"}));

    return $self->_test('is',$self->cached_stderr,'');
}

=head2  stdout_like

Check stdout for similar match.

=cut

sub stdout_like {
  my ($self, $regex, $desc) = @_;
  return $self->_test('like', $self->cached_stdout,
    $regex, _desc($desc, qq{stdout like "$regex"}));
}

sub _desc { encode 'UTF-8', shift || shift }

sub _test {
  my ($self, $name, @args) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  return $self->success(!!Test::More->can($name)->(@args));
}
1;
