package SH::ScriptX;
use autodie;
use Carp;
use List::MoreUtils q(any);
use Pod::Text::Termcap;
use File::Basename;
use Mojo::Base -base;
use Mojo::Util;
use Encode::Locale qw(decode_argv);
# use Data::Printer;

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

    __PACKAGE__->new->with_options->main if ! caller;;

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

#our $_options_values = {}; #needed by exported option
my $_options=[];
my @_extra_options=();

=head1 EXPORTED FUNCTIONS

=head2 option

TODO: Deside what is best.
Unsure if do like Applify or Getopt::Long::Descriptive or 'option', 'type','description'

Go for Getopt::Long::Descriptive this may change.
Valid keys in third argument is:

=over 1

=item default = default value

=item required: Fail if not set

=back

=head3 synopsis

option infile => string => "File for storing configuration bla bla" => {default=>'blabla.yml'}

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
If extra arguments is allowed call this methoed like $self->with_options({extra=>1}).

=cut

sub with_options {
    my $self = shift;
    die "OPTIONS NOT READ" if @_;
    warn "Method with_options is deprecated ".caller();
    return $self;
}

=head2 new

Takes key,value,key, value
New object. Special argument is options_cfg. This will set option config.

=head3 usage

__PACKAGE__->new(options_cfg => { extra => 1 }, homedir=>'/tmp')->main;

=cut

sub new {
    @ARGV = map{ Encode::decode($Encode::Locale::ENCODING_LOCALE, $_) } @ARGV;
    my $class = shift;
    my %data = @_;
    my $options_cfg = delete $data{options_cfg};
    my $self = $class->SUPER::new(%data);


    my %options;
    my @options_spec = map{$_->[0]} (@{$_options}, $self->_default_options);
    my $glp = Getopt::Long::Parser->new(config => [qw(no_auto_help no_auto_version pass_through)]);
    unless ( $glp->getoptions(\%options, @options_spec ) ) {
		die "Something is wrong"
    }

#	if ($options{help}) {
#		$self->usage;
#		exit(1);
#	}
	@$self{keys %options} = values %options;

	if ($self->{help}) {
		return $self->usage;
	}


	if (@ARGV) {
		@_extra_options = @ARGV;

		if (! defined $options_cfg || ! exists $options_cfg->{extra} || ! $options_cfg->{extra} ) {
	        say "Unexpected arguments from commandline ". join(', ', @_extra_options);
	        return $self->usage;
		}
	}

	# set value equal default if missing
	for my $o(@$_options) {
        my $name = _getoptionname($o);
        next if defined $self->{$name};
        if ( exists $o->[2]->{default}) {
            $self->{$name} = $o->[2]->{default}
        }
        if ( $o->[2]->{required} && ! defined $self->{$name}) {
            say "Argument $name is required";
            return $self->usage;
        }
	}

    # Quit if used as a module and __PACKAGE__->new->main is executed
    my @caller = caller(1);
    if (@caller && $caller[0] eq 'main') {
        return $self->gracefull_exit;
    # } elsif (! @caller) {
    #     warn "NO ".(caller(0))[0];
    # } else {
    #     warn "CALLER ".$caller[1];
    }


    no strict 'refs';
    no warnings 'redefine';
    for my $o (@{$_options}) {
        my $name = _getoptionname($o);
		die "\$name undefined ".join Dumper $o if ! $name;
		Mojo::Util::monkey_patch(ref $self, $name, sub { return $self->{$name} });

    }

    return $self;
}

=head2 extra_options

Return unexpected arguments from commandline.

=cut

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
    return $self->gracefull_exit;
}

=head2 gracefull_exit

Exit in a way that can work as object.

=cut

sub gracefull_exit {
	my $self = shift;
	# remove $self and put in a dummy that takes all methods and return.
	#...;
#	exit; # to let script run as normal for so long.
	my $return = bless {},'EXITOBJECT';
#	*EXITOBJECT::AUTOLOAD=sub{};
	Mojo::Util::monkey_patch ('EXITOBJECT',AUTOLOAD => sub {shift});
#	p $return;
	return $return;
}

sub import {
    my ($class, %args) = @_;
    my $caller = caller;
	Mojo::Util::monkey_patch($caller, 'option', \&option );
	if (-t ) {
		#binmode(STDIN,  ":encoding(console_in)");
		binmode(STDOUT, ":encoding(console_out)");
		binmode(STDERR, ":encoding(console_out)");
	}
}

=head2 arguments

This method exists mainly because of testing

=cut

sub arguments {
    my $self = shift;
    if (@_>1) {
    	if (@_ % 2 == 0 ) {
    		my %opts = {@_};
    		@$self{ keys %opts } = values %opts;
    	}
    } elsif (@_ ==1 ) {
    	if (ref $_[0] eq 'HASH') {
    		my %opts = %{ $_[0] };
            @$self{keys %opts} = values %opts;
        } else {
    	    my $commandline = "cmd " . shift;
    	    if ( eval "require Parse::CommandLine;1;") {
                ...;
    	    } else {
                my @args = split( /\s\-\-?/, shift);
                ...;
    	    }
        }
	} elsif (@_==0) {
		warn "Nothing to do";
	} else {
		die "Wrong arguments " . join(", ",@_);
	}
    # Find module to read commandline
    return $self;
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
	my $script;
	$script = basename($0);

	my $return = "\n" . sprintf"$script %s\n\n",(@$_options ? '[OPTIONS]' : '');
	for my $o (@$_options) {
		my ($def,$desc,$other) =@$o;
		next if $other->{hidden};
		next if $desc eq 'hidden';
        my ($name,$type) = split (/\b/,$def,2);
        if ($type eq '=s') {
            $type = '<STRING>';
        } elsif ($type eq '=i') {
            $type = '<INTEGER>';
        } elsif ($type eq '=o') {
            $type = '<OTHER>';
        } elsif ($type eq '=f') {
            $type = '<FLOAT>';
        } elsif ($type eq '!' || $type eq '+') {
            $type ='';
        } else {
            die "Unknown option '$def'";
        }
		$return .= sprintf("         --%-15s    %-80s\n", "$name $type" , $desc);

	}

	return $return."\n\n";
}

=head1 SEE ALSO

 Applify

=head1 AUTHOR

Slegga - C<steihamm@gmail.com>

=cut

1;
