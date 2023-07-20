package SH::ScriptX;
use 5.24.1;

use autodie;
use Carp;
use List::MoreUtils q(any);
use Pod::Text::Termcap;
use File::Basename;
use Mojo::Base -strict,-base,-signatures;
use Mojo::Util;
use Encode::Locale qw(decode_argv);
use IO::Interactive;
no warnings "experimental::signatures";
use feature qw/signatures say/;
use Data::Dumper;
use Data::Printer;

# use Data::Printer;

=encoding utf8

=head1 NAME

SH::ScriptX - Development of a lite version of Applify

=head1 SYNOPSIS

    use SH::ScriptX; # call SH::ScriptX->import
    use Mojo::Base 'SH::ScriptX', -signatures;

    has info => 'blabla';
    option 'name=s', 'from emailadress', {validation => qr'[\w\.\@]+'};
    print '__PACKAGE__ is:' . __PACKAGE__. "\n";


    sub main($self) {
        say "Hi ".$self->name;
        say "Info ".$self->info;
        return $self->gracefull_exit;
    }

    __PACKAGE__->new->main;

# perl script/test-scriptx.pl --name Wood Head
# perl script/test-scriptx.pl --help
# perl script/test-scriptx.pl --usage

=head1 DESCRIPTION

Warning this module is experimental. Functionality may suddenly change.

This is an alternative to Applify and SH::Script

This module makes it easy to document input parameters. And script --help will show
all of the documentation.

This  module makes it easy to test and manipulate scripts with tests.

=head2 Reason for this module

Easy to test and write useful tests. Easy to manipulate the test object while simulate running of scripts using this module.

I like to debug. It is easier to debug than Applify but not as easy as with plain perl.

Anonymous subroutines which you have to use in Applify is hard to debug in the tools I have seen so far.

I like to see the main code when I open a script and not just a tiny wrapper/proxy for a main script module.

=head1 TODO

Show an example of a test to show where script as module really shines.

=cut

#our $_options_values = {}; #needed by exported option
my $_options=[];

=head1 ATTRIBUTES

=head2 extra_options

Container in the form of an array ref where unexpected options is placed.

=cut

has extra_options=>sub {[]};
has 'scriptname';
=head1 EXPORTED FUNCTIONS

=head2 option

TODO: Decide what is best.
Unsure if do like Applify or Getopt::Long::Descriptive or 'option', 'type','description'

Go for Getopt::Long::Descriptive this may change.
Valid keys in third argument is:

=over 1

=item default = default value

=item required: Fail if not set

=back

=head3 synopsis

option infile => string => "File for storing configuration." => {default=>'my-config.yml'}

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
    no strict 'refs'; ## no critic
    push @$_options, [$declare,$description,\%args];
    use strict 'refs';
}

=head1 METHODS

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

	@$self{keys %options} = values %options;

	if ($self->{help}) {
		return $self->usage(1);
	}

	if ($self->{usage}) {
		return $self->usage(0);
	}


	if (@ARGV) {
		$self->extra_options([@ARGV]);

		if (! defined $options_cfg || ! exists $options_cfg->{extra} || ! $options_cfg->{extra} ) {
	        say "Unexpected arguments from commandline ". join(', ', @{$self->extra_options});
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
    if (scalar @caller ) {
    	if( exists $caller[0] && defined $caller[0] && ($caller[0] eq 'main' || $caller[0] =~ '(SH\:\:)?Test\:\:ScriptX') ) {
	        return $self->gracefull_exit;
	    }
    }

    # } elsif (! @caller) {
    #     warn "NO ".(caller(0))[0];
    # } else {
    #     warn "CALLER ".$caller[1];


    no strict 'refs';	## no critic
    no warnings 'redefine';## no critic
    for my $o (@{$_options}) {
        my $name = _getoptionname($o);
		die "\$name undefined ".join Dumper $o if ! $name;
		Mojo::Util::monkey_patch(ref $self, $name, sub { return $self->{$name} });

    }
	use strict 'refs';
	use warnings 'redefine';
    return $self;
}


=head2 usage

args: $podfile, $verboseflag
Print out'usage', help message and exit.
If verbose flag is on then print the pod also.

=cut

sub usage($self,$verbose=0) {
    say $self->_gen_usage;
    if ($verbose) {
        my $parser=Pod::Text::Termcap->new(sentence => 0, width => 120 );
	    $parser->parse_from_filehandle($0);
    }
   	return $self->gracefull_exit;
}

=head2 gracefull_exit

    return $self->gracefull_exit;

Exit in a way that can work as object.
Use this method instead og exit to stop script. Exit is hard for Test::ScriptX to catch.
Use in combination with return or else there will be no exit.

=cut

sub gracefull_exit($self) {
	# remove $self and put in a dummy that takes all methods and return.
	#...;
#	exit; # to let script run as normal for so long.
	my $return = bless {},'EXITOBJECT';
	Mojo::Util::monkey_patch ('EXITOBJECT',AUTOLOAD => sub {shift});
	return $return;
}

 sub import {
     my ($class, %args) = @_;
     my $caller = caller;
 	Mojo::Util::monkey_patch($caller, 'option', \&option );
 	if (IO::Interactive::is_interactive ) {
 		#binmode(STDIN,  ":encoding(console_in)");
 		binmode(STDOUT, ":encoding(console_out)");
 		binmode(STDERR, ":encoding(console_out)");
 	}
}

=head2 arguments

This method exists mainly because of testing

=cut

sub arguments($self, @args) {
    if (@args>1) {
    	if (@args % 2 == 0 ) {
    		my %opts = {@args};
    		@$self{ keys %opts } = values %opts;
    	}
    } elsif (@args ==1 ) {
    	if (ref $args[0] eq 'HASH') {
    		my %opts = %{ $args[0] };
            @$self{keys %opts} = values %opts;
        } else {
    	    my $commandline = "cmd " . shift @args;
    	    if ( eval {require Parse::CommandLine;1;}) {
                ...;
    	    } else {
                my @args = split( /\s\-\-?/, @args);
                ...;
    	    }
        }
	} elsif (@args==0) {
		warn "Nothing to do";
	} else {
		die "Wrong arguments " . join(", ",@args);
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
    return (['help!','This help text'],['usage!','Short usage'],['version!','Show version']);
}

sub _gen_usage($self) {
	my $script;
	$script = $self->scriptname || basename($0);

	my $return = "\n" . sprintf"$script %s\n\n",(@$_options ? '[OPTIONS]' : '');
	for my $o (@$_options,_default_options()) {
		my ($def,$desc,$other) =@$o;
		next if $other->{hidden};
		die "Missing description for '$def'. Please enter." if !defined $desc;
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
            die "Unknown option $type '$def'";
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
