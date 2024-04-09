package SH::PassCode::File;
use Mojo::Base -base, -signatures;
use Data::Printer;
use IPC::Run qw/timeout harness start pump finish/;
use Carp qw/cluck confess/ ;

=head1 NAME

SH::PassCode::File

=head1 SYNOPSIS

    my $pcf = SH::PassCode::File->new('finance/golddiggerbank','secretpw',{url=>'golddigger.com',username=>'social security number'});
    my $password = $pcf->password; # secretpw


=head1 DESCRIPTION

Designed to be a sub utility class for making easier for SH::PassCode to manipulate password files.

=head1 ATTRBIUTES

=head2 password

=head2 filepath

=head2 changed

=head2 username

=head2 url

=head2 comment

=head2 extra - {secrect question: secret answer}

=head2 dir - Alternative password dir

ENVIRONMENT VARIABLES

=over 4

=item PASSWORD_STORE_DIR - Alternative directory for password store

=back

=cut

has ['filepath','password', 'changed', 'username', 'url', 'comment', 'extra', 'dir'];

=head1 FUNCTIONS

=head2 new

    my $pcfile = SH::PassCode::File->new('type/filename');

=head2 from_file

    SH::PassCode::File->from_file('type/name');

Return a SH::PassCode::File if file is found. Else return undef

=cut

sub from_file($class,$filepath, $args = undef) {
    my $subdir;
    if ($args->{dir}) {
        my $dir = $args->{dir};
        $subdir = sub {$ENV{PASSWORD_STORE_DIR}="$dir"};
    }

    my $stdout = _xrun($subdir, {ok_errors => ['is not in the password store.']}, "pass", "code", "show", $filepath);
    return if ! $stdout;
    p $stdout;

    my $hash ={filepath => $filepath};
    my $lastkey;
    my $key;
    my $value;
    for my $l( split(/\n/, $stdout) ) {
        if (! grep {$_ ne 'filepath'} keys %$hash) {
            $hash->{password} = $l;
            next;
        }
        if ($l =~ /^(\w+)\:\s*(.*)/) {
            ($key, $value) = ($1,$2);
        }
        else {
            $value = $l;
        }
        if (!$key && $l) {
            p $stdout;
            say "errorline: $l";
            ...;
        }
        if ($key eq 'comment') {
            $hash->{$key} .= ($hash->{$key} ? "\n" : '') . $value;
        }
        elsif (grep {$key eq $_} (qw/filepath username url changed/)) {
            $hash->{$key} = $value;
        }
        else {
            $hash->{extra}->{$key} .= ($hash->{extra}->{$key} ? "\n" : '') . $value;
        }

        $lastkey = $key if $key;
    }

    $hash->{dir} = $args->{dir} if $args->{dir};
    my $return = $class->new(%$hash);
    return $return;
}

=head2 okeys

Return array of object keys


=cut

sub okeys($class) {
    return (qw/filepath password changed username url comment extra/);
}


=head1 METHODS

=head2 to_file

Write to file. Replace existing.


=cut

sub to_file($self, $args = undef) {

    if (! defined $self->password &&  $self->url ne 'http://sn') {
        say "ERROR:";
        p $self;
        die "Missing password";
    }
    my $cont = $self->password . "\n";
    for my $k(qw/filepath changed username url comment/) {
        $cont .= "$k: " . $self->$k."\n" if $self->$k;
    }

    my $extra = $self->extra;
    if ($extra) {
        for my $k(keys %$extra) {
            $cont .= "$k: " . $self->extra->{$k}."\n";
        }
    }
    my $dir;
    my $subdir;

    if ($args->{dir} || $self->dir) {
        $dir = $args->{dir} || $self->dir;
        $subdir = sub {$ENV{PASSWORD_STORE_DIR}="$dir"};
    }

    _xrun($subdir, {stdin=>$cont,ok_errors=>['tr\: write error']},"pass", "code", "insert", "-m", "-f", $self->filepath);
}


=head2 delete

Remove the password file.

=cut

sub delete($self) {
    my $subdir;
    if ($self->{dir}) {
        my $dir = $self->dir;
        $subdir = sub {$ENV{PASSWORD_STORE_DIR}="$dir"};
    }
    if (! defined $self->filepath) {
        $DB::single = 2;
        p $self;
        die "filepath is undef";
    }
    if (_xrun( $subdir, "pass", "code", "rm","-f", $self->filepath ))     {
        return SH::PassCode::File->new;
    }
    return;
}

sub _xrun($subdir, @cmd) {
    my $config ;
    if ( ref $cmd[0] ) {
        $config = shift @cmd;
    }
    confess("Missing arguments") if ! @cmd;
    my @configs;
    if ($subdir) {
        @configs = (init => $subdir);
    }

    my ($stdin,$stdout,$stderr,$rcode);
        my $h = harness \@cmd,
        \$stdin, \$stdout, \$stderr, @configs, ( my $t = timeout 10 );#, (my $t = timeout(5, exception => 'timeout'));
        start $h;
        if (exists $config->{stdin}) {
            cluck "cmd: ".join(' ', @cmd);
    #        p $config;
    #        $stdin = $config->{stdin};
            $config->{stdin} =~ s/\s+$//mg;
            $config->{stdin} .="\n";
            my $end = $config->{stdin};
            $end =~ s/.*\n//mg;
            say STDERR "\$end $end";
#            pump $h until ! length $stdin;
            sleep(1);
            my $prev_stdout = 'gfsgfbsgdbhbhgbh';
            while ( $stdin || !$stdout || $prev_stdout ne $stdout) { #index($stout,$end) < 0) {
                if (! $stdout) {
                    pump $h;
                    sleep 1;
                    say STDERR 'a';

                    next;
                }
                $prev_stdout = $stdout;
                $stdin = $config->{stdin};

                say STDERR "X-'$stdout'";
                say STDERR "stdin '$stdin'";
                eval {
                    pump $h;
                } or do {
                    say "$@";
#                    pump $h
                };
#                say STDERR $stderr;
#                say STDERR "stdout:'$stdout'";
            }
            say STDERR "after pump";
        }
    eval {
        $rcode = finish $h;
    };
    say STDERR "after finish";
    if ( $@ ) {
        my $x = $@;
        chomp($x);
        $h->kill_kill;
        if ($x !~ /^timeout/ ) {
            say "error: ".join(' ', @cmd);
            say $stderr;
            say $stdout;
            die "die with error '$x'";
        }
        else {
            say "timeout";
            $rcode = 0;
        }
    }
    if ($rcode>1) {
        die "$rcode $stderr";
    }
    if ($stderr ) {
        my $err = $stderr;
        chomp($err);
        if ($config && $config->{ok_errors}) {
            if (grep {$err =~ /$_/} @{$config->{ok_errors}}) {
                return $stdout;
            }
        }
        say "Error with command: ".join(' ', @cmd);
        if ($err eq 'Could not decrypt pass-code store') {
            say "Try: run 'pass code ls' and when try again";
        }
        die "$rcode $stderr";
    }
    return $stdout if ! exists $config->{stdin};
    $stdin = $config->{stdin} ;
}
1;