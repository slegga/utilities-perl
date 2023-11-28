package SH::PassCode;
use Mojo::Base -base, -signatures;
use IPC::Run qw/run/;
use Data::Printer;
use SH::PassCode::File;

=head1 NAME

SH::PassCode - Interface to pass code

=head1 SYNOPSIS

    use SH::PassCode;
    my $pc = SH::PassCode->new;
    $pc->create('finance/nordea', 'my password', {username=>'myuser', url=>'mybank.com',comment=>'savings'});
    say $pc->list->map($_->name)->each;
    say $pc->list_tree->each;
    say $pc->list('finance')->each;
    say $pc->show('finance/nordea');

=head1 DESCRIPTION

This module is the interface for pass code to store password and secrets.

This module finds password/secrets in SH::PassCode::File objects. Se perldoc SH::PassCode::File for more info

=head1 PREQUERIES

Installation of pass - https://www.passwordstore.org/

Installation of pass code - https://github.com/alpernebbi/pass-code

Initialzation of pass code:

=head1 ATTRIBUTES

=head2 dir - The path to the password store directory.

=cut

has 'dir';

=head1 METHODS

=head2 list

    my @items = $pc->list('finance');

Return a list of SH::PassCode::Item that is placed in directory.

=cut



sub list($self, $path) {
    if ($self->dir) {
        ...;
    }
    my $rcode = run [ "pass", "code", "ls", $path ],
    \my $stdin, \my $stdout, \my $stderr;

    if ($rcode>1) {
        warn " $rcode: $stderr";
    }
    if ($stderr) {
        warn $stderr;
    }

    return if ! $stdout;
    p $stdout;
#   unittest
#   ├── 10.0.0.23
#   └── paypal.com
    my @filenames;
    for my $l(split(/\n/,$stdout) ) {
        next if ($l eq $path);
        my $f;
        (undef, $f) = split(/ /,$l,2);
        push @filenames, "$path/$f";
    }
    my @files = map { SH::PassCode::File->from_file($_) } @filenames;
    return @files;
}

=head2 list_tree

    my @items = $pc->list_tree('finance');

Return a list of SH::PassCode::File that is placed in directory tree. None is root.

=head2 query

    my @items = $pc->query({username => qr'.+'});
    my @items = $pc->query({any => qr'www'});
    my @items = $pc->query({updated => {before => '1999-01-01'}});

Return list of SH::PassCode::File

=head2 write_file

    my $file = $pc->write_file('type/filename', 'password',{username=>'username', url=>'www.example.com', comment=>'Yadyada'});

Create the file if not exists or update the file if exists with.

=cut



=head2 delete_file

    $pc->delete_file('type/filename');

=cut

sub xsystem($self,$command) {
    my ($stdout, $stderr)  = capture {
        system($command);
    };
    if ($stderr) {
        say "";
        say "ERROR with: $command";
        say "STDERR:";
        say $stderr;
        say "\nSTDOUT:";
        say $stdout;
        confess("OS command error");
    }
    return $stdout;
}

1;
