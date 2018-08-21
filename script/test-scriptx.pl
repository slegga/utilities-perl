#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;
use 5.016;

# Call SH::ScriptX->import
use SH::ScriptX;

#Define the script object.
use Mojo::Base 'SH::ScriptX';

=head1 NAME

=encoding utf8

test-nx-mojo-script.pl

=head1 SYNOPSIS

test-scriptx.pl --from ølmage --stdin # testing the SH::ScriptX module

=head1 DESCRIPTION

Test with options.

=head1 AUTHOR

Slegga C<steihamm@gmail.com>

=cut

has info => 'blabla';
option 'stdin!','Turn on STDIN';
option 'from=s', 'from emailadress', {validation => qr'[\w\.\@]+'};
# option 'subject=s', 'Email Subject. Also used to find the to address if not supported',qr/\w/;
# option 'info!', 'Print out schema for where to send emails', qr/^\w+$/;
# print '__PACKAGE__ is:' . __PACKAGE__. "\n";
# print \%::;
#__PACKAGE__->with_options->main();
__PACKAGE__->new->with_options->main();
sub main {
    my $self = shift;
    print Dumper $SH::ScriptX::_options_values;
    print Dumper $SH::ScriptX::_options;
        say "Hi ".($self->from//'__NULL__');
    say "Info ".$self->info;
    print "STDIN:";
    my $stdin= <STDIN>;
    say "stdin: $stdin";
}
1;
