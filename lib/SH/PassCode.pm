package SH::PassCode;
use Mojo::Base -base, -signatures;
use IPC::Run qw/run/;
use Data::Printer;
use SH::PassCode::File;
use Capture::Tiny qw/capture/;
use File::Basename;
use Carp 'croak';


=head1 NAME

SH::PassCode - Interface to pass code

=head1 SYNOPSIS

    use SH::PassCode;
    my $pc = SH::PassCode->new;
    $pc->create('finance/nordea', 'my password', {username=>'myuser', url=>'mybank.com',comment=>'savings'});
    say $pc->list('')->map($_->name)->each;
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

=head1 ENVIRONMENT VARIABLES

=over 4

=item PASSWORD_STORE_DIR - The path to the passwordstore. default ~/.password-store

=back

=head1 ATTRIBUTES

=head2 password_dir - The path to the password store directory.

=cut

has password_dir => sub {
    return $ENV{PASSWORD_STORE_DIR}||$ENV{HOME}.'/.password-store';
};

has 'git_pulled'; # Mark if git pull is ran.
has osname => sub {my $self =shift; my ($x) = $self->xsystem('uname'); chomp $x;return $x};


=head1 METHODS

=head2 list

    my @items = $self->list('finance');

Return a list of SH::PassCode::Item that is placed in directory.

=cut


=head2 list

List friendly filename and catalogs in given path

=cut

sub list($self, $path, $sopts = {}) {
#   unittest
#   ├── 10.0.0.23
#   └── paypal.com
    my @filenames = keys %{$self->get_files()};
    my %files = ();
    for my $l( @filenames ) {
        if ($l =~ s/^$path//) {
            my $tmp = $l;
            $tmp =~ s/^\///;
            if ( $tmp =~ s/\/.*// ) {
            }else {
                if ($sopts->{dir_only}) {
                    next;
                }
            }
            $files{$tmp}++;
        }
    }
    my $return = [sort keys %files];
#    p $return;
    return $return;
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

=head2  get_files

    my $files_as_array_ref =$self->get_files('site');

Takes regexp of a file.

Return friendlyname as key and real name as value.

return {filename=>'encodedfilename',filename2=>'encodedfilename.gpg'}

=cut

sub get_files ($self,$regex = undef) {
    my $return;
    my $errfilename = "/tmp/".basename($0)."-$$.err";
    my ($out,$err) = $self->xsystem("gpg --decrypt ".$self->password_dir."/.passcode.gpg");;
    for my $l(split(/\n/, $out)) {
        my ($real,$friendly) = split (/\:/, $l);
        die "Missing : in $l     err: $err" if !$friendly;
        next if ($regex && $friendly !~ /$regex/);
        $return->{$friendly} = $real;
    }

    return $return;
}

=head2 git_pull

    $self->git_pull;

Do a git pull for the password-store

=cut

sub git_pull($self) {
    return 0 if $ENV{NO_GIT};
    return 0 if $self->git_pulled;
    my $githome = $self->password_dir;
    say '*'.$self->osname.'*';
    my ($last_pull,$err);
    my $datefile = "~/$githome/.git/FETCH_HEAD";
    eval {
        if (! -e $datefile) {
            $last_pull = 0;
        }
        else {
            ($last_pull,$err) = $self->xsystem($self->osname ne 'Darwin' ? "stat -c %Y $datefile" : "stat -t%Y $datefile |cut -f1 -d' '" );
        }
    };
    say $@ if $@;
    chomp $last_pull if defined $last_pull;
    $last_pull||=0;
    if ($last_pull =~ /\D/) {
        die "Error: ".$last_pull. ' -- '.$err;
    }
    if (time() - $last_pull> 3600 *24 * 1) {
        my ($out,$err) =  $self->xsystem("pass code git pull");
        say $out if $out;
        die $err if $err;
        $self->git_pulled(1);
        return 1 ;
    }
    return 0;
}


=head2 xsystem

    my $stdin = 'hello';
    my ($stdout,$stderr) = $self->xsystem('echo',$stdin);

Run command on OS

=cut

sub xsystem($self,$command, $stdin = undef, $config = {}) {
    use IPC::Run3;    # Exports run3() by default
    my @cmd;
    if (ref $command ) {
        @cmd = @$command;
    }
    else {
        @cmd = split / /, $command;
    }
    my ($stdout,$stderr);
    run3 \@cmd, \$stdin, \$stdout, \$stderr;
#    my ($stdout, $stderr)  = capture {
#        system($command);
#    };
    chomp $stderr;
    if ($stderr) { #  && $stderr =~/err/i
        $stderr =~ s/^bind.+?Address already in use\s*//;
        $stderr =~ s/^channel_setup.+?\n//;
        $stderr =~ s/^Could not request local forwarding.\s*//;
        $stderr =~ s/^This system.+a court of law.\s*//m;

		if (!$stderr ) {
			# ignore ssh warnings
		}
        elsif ( index ($stderr,'is not in the password store.')>=0 ) {
            $stdout = undef;
            # accept error
        }
        elsif ($stderr =~ /^gpg\: kryptert med|^gpg\: encrypted with/) {
            # dummy err
            $stderr ='';
        }
        elsif ($stderr =~ /bash\: warning: setlocale/) {
            # ignore

        }
        elsif ($config->{continue_on_error}) {
            # do nothing
        }
        else {
            say "";
            say "ERROR with: ".(ref $command ? join(' ', @$command) : $command);
            say "STDERR:";
            say $stderr;
            say "STDOUT:" if $stdout;
            say $stdout  if $stdout;
            croak("OS command error");
            #confess("OS command error");
        }
    }
    return $stdout, $stderr;
}

1;
