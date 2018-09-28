#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../lib";
use 5.016;
use Data::Dumper;
# Call SH::ScriptX->import
use SH::ScriptX;
#Define the script object.
use Mojo::Base 'SH::ScriptX';

=head1 NAME

=encoding utf8

test-scriptx.pl

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


sub main {
    my $self = shift;
    print Dumper $SH::ScriptX::_options_values;
    print Dumper $SH::ScriptX::_options;
    say "Info ".$self->info;
        say "Hi ".($self->from//'__NULL__');
#    print "STDIN:";
#    my $stdin= <STDIN>;
#    say "stdin: $stdin";
}

__PACKAGE__->new->main();

1;
