package SH::ScriptX;
use autodie;
use Carp;
use List::MoreUtils q(any);
use Pod::Text::Termcap;
use File::Basename;
use Mojo::Base -base;
use Mojo::Util;
use Encode::Locale qw(decode_argv);
#use Getopt::Long qw(:config permute );
=encoding utf8

=head1 NAME

SH::ScriptX - Development of a lite version of Applify

=head1 SYNOPSIS

    use SH::ScriptX; # call SH::ScriptX->import
    use Mojo::Base 'SH::ScriptX';

    SH::ScriptX->import;

    has info => 'blabla';
    option 'name=s', 'from emailadress', {validation => qr'[\w\.\@]+'};
    print '__PACKAGE__ is:' . __PACKAGE__. "\n";

    __PACKAGE__->new->with_options->main();

    sub main {
        my $self = shift;
        say "Hi ".$self->name;
        say "Info ".$self->info;
    }
    1;

# perl script/test-scriptx.pl --name tittentei
# perl script/test-scriptx.pl --help

=head1 DESCRIPTION

Warning this module is experimental. Funtionality may sudently change.

This is an alternative to Applify and SH::Script

The main method is with_options. Shall be called like in the synopsis right after new.
This module makes it easy to document input parameters. And script --help will show
all of the documentation.

Script as Module makes it easy to test and manipulate in a test script.

=head2 Reason for this module

I like to debug.

Anonymous subroutines which you have to use in Applify can not be debugged in the tools I have seen so far.

I like to se the main code when I open a script and not just a wrapper/proxy for a main script module.

=head1 TODO

Show an example of a test to show where script as module really shines.

=cut

our $_options_values = {};
our $_options=[]; # needed by  exported option sub
my @_extra_options=();

=head1 EXPORTED FUNCTIONS

=head2 option

args: podfile \@ARGV, $usage_desc, @option_spec, \%arg
podfile:        usually $0
\@ARGV:         input from shell
$usage_desc:    "%c %o"
@option_spec:   array of array ref. Inner array: ["option|flag", "option description", options]
\%arg:          input for describe_options method, in addition to return_uncatched_arguments => 1 for leaving unhandled arguments in @ARGV

Input types: s=string i=integer, none=Boolean

This method is a overbuilding og Getopt::Long::Descriptive. Check for options not read. Remove error message when putting an --help when there is a required option.

=cut

sub option {
    my $declare = shift;
    my $description = shift;
    my $caller =caller;
    my %args;
    if (@_ == 1 && ref $_[0] eq 'HASH') {
        %args = %{$_[0]};
    }
    elsif (! (@_ % 2) ) {
        %args = @_;
    }
    else {
        die"Ekstra arguments hash to be like key =>'value',key =>'value': " . join(', ',@_);
    }
#    say "declare: " . $declare;
#    p $description;
    my $name = $declare;
    $name =~ s/\W.*//;
    no strict 'refs';
    push @$_options, [$declare,$description,\%args];
}

=head1 METHODS

=head2 with_options

Should be called right after new.

This method show help if in arguments.

=cut

sub with_options {
    @ARGV = map{ Encode::decode($Encode::Locale::ENCODING_LOCALE, $_) } @ARGV;
    my $self = shift;
    my $caller = caller;
    my %options;
    my @options_spec = map{$_->[0]} (@{$_options}, $self->_default_options);
    my $glp = Getopt::Long::Parser->new(config => [qw(no_auto_help no_auto_version pass_through)]);
    unless ( $glp->getoptions(\%options, @options_spec ) ) {
		die "Something is wrong"
    }

	if ($options{help}) {
		$self->usage;
		exit(1);
	}

    $_options_values = \%options;

	@_extra_options = @ARGV;
    no strict 'refs';
    no warnings 'redefine';
#	my $class = ref $self;
    for my $o (@{$_options}) {
        my $name = _getoptionname($o);
#        *{"$class::$name"} = sub {$_[0]->_options_values->{$_[1]}};
		die "\$name undefined ".join Dumper $o if ! $name;
		Mojo::Util::monkey_patch($caller, $name, sub { return $_options_values->{$name} });

    }
    return $self;
}

sub extra_options {
	my $self = shift;
	return @_extra_options;
}

=head2 usage

args: $podfile, verboseflag
Print out help message and exit.
If verbose flag is on then print the pod also.

=cut

sub usage {
	my $self = shift;
#    print BOLD $usage->text;
    my $parser=Pod::Text::Termcap->new(sentence => 0, width => 120 );
    say $self->_gen_usage;
    $parser->parse_from_filehandle($0);
    exit;
}

sub import {
    my ($class, %args) = @_;
    my $caller = caller;
	Mojo::Util::monkey_patch($caller, 'option', \&option );
	binmode(STDIN,  ":encoding(console_in)");
	binmode(STDOUT, ":encoding(console_out)");
	binmode(STDERR, ":encoding(console_out)");
}


# _getoptionname
#
# Takes option as an array refs

sub _getoptionname {
    local $_ = $_[0]->[0] or return;
    s/[\W].*//;
    return $_;
}

sub _default_options {
    return (['help','This help text'],['version','Show version']);
}

sub _gen_usage {
	my $script = basename($0);

	my $return = sprintf"$script %s\n\n",(@$_options ? '[OPTIONS]' : '');
	for my $o (@$_options) {
		my ($def,$desc,$other) =@$o;
		$return .= sprintf("          %-15s    %-80s\n", $def, $desc);

	}

	return $return."\n\n";
}

#sub _process {
#	push @_extra_options, shift;
#}

=head1 SEE ALSO

 Applify

=head1 AUTHOR

Slegga - C<steihamm@gmail.com>

=cut

1;
