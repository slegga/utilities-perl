package SH::Ask;
use Carp;
use Mojo::Base -strict;
use Term::ReadKey;

use Exporter 'import';
our @EXPORT_OK = qw /ask/;


my %answer_defaults=();


=head1 NAME

SH::Ask - Ask user.

=head1 SYNOPSIS

    use SH::Ask 'ask';
    $years = ask "How old are you?",qr(\d+);


=head1 DESCRIPTION

A module for asking the user questions. Should maybe use a CPAN module.

=head1 FUNCTIONS

=head2 ask

 question = text
 choices_ar = choices_ar or a qr regexp
 {
   exit_on_nochoice 0 = repeat till ok answer, 1 = stop script, 2 = continue
   forced_answer    The answer when force flag is set.
   is_forced        0=wait for user, 1=computer choose, 2=comp choose and quiet
   remember =       [0|1] remember last answer and set this to default
   secret           [0|1] no show stdin to shell
 }

Ask user questions like Are you sure? or What is your favorite color?
Input is STDIN

=cut

sub ask {
    my $question = shift;
    my $choices_ar = shift;
    my $options_hr = shift;
    my $default;
    if (ref $options_hr eq 'HASH'){
        if (exists $options_hr->{forced_answer}) {
            $default = $options_hr->{forced_answer};
        } elsif ( $options_hr->{'remember'} && exists $answer_defaults{$question}) {
            $default = $answer_defaults{$question};
        }
    }
    confess "Argument spare @_" if @_;
    my $answer;
        if (! defined $choices_ar and (! defined $options_hr )) {
            # Typically Press any key to continue questions
            print $question;
            ReadMode 4; # Turn off controls keys
            while (not defined ($answer = ReadKey(-1))) {
                    # No key yet
            }
            #print "Get key $key\n";
            ReadMode 0; # Reset tty mode before exiting
            print "\n";
        } elsif ( defined $choices_ar ) {
            while (1) {
                #Print question
                if (! defined $options_hr ||! exists $options_hr->{is_forced} ||!defined $options_hr->{is_forced} || $options_hr->{is_forced} != 2) {
                    print "$question ";
                    if (ref $choices_ar eq 'ARRAY') {
                        print "(".join(',',@$choices_ar).")";
                    } else {
                        print $choices_ar;
                    }
                    if ($default) {
                        print '['.$default.']';
                    }
                    print "? ";
                }
                #user in control
                if (! defined $options_hr || ! exists $options_hr->{is_forced} || ! $options_hr->{is_forced} ) {
                    # print "$question ";
                    $answer = _ask_stdin($options_hr->{secret});
                    my @dummy;
                    if ( $choices_ar =~ /^\(\?/ ) {
                        if (lc($answer) =~ /^$choices_ar$/) {
                            last;
                        }
                    } else {
                        @dummy = grep({lc($answer) eq lc($_)} @$choices_ar);
                    }
    #                print "dummy[0]:".$dummy[0],"\n" if @dummy;
                    if (! @dummy ) {
                        if (defined $options_hr && exists $options_hr->{exit_on_nochoice} && $options_hr->{exit_on_nochoice} == 1){
                            croak("Execution stopped by user.")
                        } elsif ($default && !$answer) {
                            $answer = $default;
                            last;
                        } elsif (($options_hr->{exit_on_nochoice}//0) == 2) {
                            $answer = undef;
                            last;
                        }
                    } else {
                        last;
                    }
                #computer in control
                } else {
                    if (!($options_hr->{exit_on_nochoice} && ! $options_hr->{forced_answer} ) && ! any {$default eq $_} grep {defined }@$choices_ar) {
                        confess "Forced answer is not in the valid answer list: $options_hr->{forced_answer}, (".join(',',@$choices_ar).")\n";
                    }
                    if ($options_hr->{is_forced} != 2) {
                        print $default,"\n";
                    }
                    $answer = $default;
                    last;
                }
            }
        } else {
            confess "Must either have choices and options or none";
        }
    if ($options_hr->{'remember'}) {
        $answer_defaults{$question} = $answer;
    }
    return $answer;
}

sub _ask_stdin {
    my $hidden_f =shift;
    my $return;
    if ($hidden_f) {
        ReadMode('noecho'); # don't echo
    }
    $return = <STDIN>;
    if ($hidden_f) {
        ReadMode(0); # back to normal
        print "\n";
    }
    chomp ($return);
    return $return;
}

1;
