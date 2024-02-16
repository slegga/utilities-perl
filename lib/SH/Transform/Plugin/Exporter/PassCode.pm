package SH::Transform::Plugin::Exporter::PassCode;
use Mojo::Base 'SH::Transform::Exporter', -signatures;
use Mojo::File 'path';
use Mojo::JSON qw/encode_json/;
use POSIX 'strftime';
use Data::Printer;
use SH::PassCode;
use File::Basename;
use SH::Ask qw /ask/;

=head1 NAME

SH::Transform::Plugin::Exporter::PassCode - create files and fills them with pass code encrypted data.

=head1 SYNOPSIS

    use SH::Transform;
    my $trans = SH::Transform->new(Exporter=>SH::Transform::Plugin::Exporter::PassCode->new);
    $trans->transform({file=>'test.json'},{type=>'PassCode'});

=head1 DESCRIPTION

Enable export to passcode. Split work and personal passwords.

Personal password is exported to ~/.password-store

Work password is exported to ~/.work-password-store

=head1 METHODS

=head2 is_accepted

Decide if moduke is usable for the task or not.

=head2 export

Verify data, transform and write to a pass code directory for private and work. See perl code for criteria for which password is marked as private and which is work.

=cut

has passcode => sub { SH::PassCode->new };

sub is_accepted ($self, $args) {
    return 1 if exists $args->{type} && lc($args->{type}) eq 'passcode';
    return 0;
}

sub export ($self, $args, $data) {

    # TRANSFORM
    my @formated_data;         # ({filepath,password,username,url,change,comment,{extra}})
    my @work_formated_data;    # ({filepath,password,username,url,change,comment,{extra}})
                               #if lastpass
    if (exists $data->[0]->{name} && $data->[0]->{name}) {

        # url,username,password,totp,extra,name,grouping,fav
        for my $r (@$data) {
            my $nr;
            my @accepted_keys = qw/grouping name password username url totp fav extra/;
            for my $k (keys %$r) {
                if (!grep { $k eq $_ } @accepted_keys) {
                    die "Unknown key: $k in Last Pass format";
                }
            }

            $nr->{filepath} = $r->{grouping} ? $r->{grouping} . "/" . $r->{name} : $r->{name};
            for my $k (qw/ password username url/) {
                $nr->{$k} = $r->{$k};
            }
            $nr->{changed} = my $date = strftime '%Y-%m-%d', localtime;
            $nr->{comment} = $r->{extra};
            $nr->{comment} .= ',totp:' . $r->{totp} if $r->{totp};
            $nr->{comment} .= ',fav:' . $r->{fav}   if $r->{fav};
            $nr->{dir} = $args->{dir} if $args->{dir};
            if (!exists $nr->{filepath} || !$nr->{filepath}) {
                next if (grep { defined $_ } values %$nr) == 2;    # ignore no secrets
                say "---";
                p $nr;
                p $r;
                die "Missing file path";
            }
            elsif ($nr->{filepath} =~ /jobb|Business/i) {
                $nr->{filepath} = basename($nr->{filepath});
                push @work_formated_data, $nr;
            }
            else {
                push @formated_data, $nr;
            }
        }

    }

    # passordfil
    elsif (exists $data->[0]->{SYSTEM}) {
        for my $r (@$data) {
            my $nr;
            my @accepted_keys = qw/id  DOMENE GRUPPERING SYSTEM URL BRUKER PASSORD BESKRIVELSE BYTTE/;
            for my $k (keys %$r) {
                if (!grep { $k eq $_ } @accepted_keys) {
                    die "Unknown key: $k in passordfil format";
                }
            }
            my $filename = ($r->{SYSTEM} // $r->{url} // die encode_json($r));
            $filename =~ s/\s/_/g;
            $filename =~ s/^https?+:\/\///g;
            $filename =~ s/[\/:].*//;
            if (!$filename) {
                next if !$r->{password};
                p $r;
                die "No filename";
            }


            $nr->{filepath} = ($r->{GRUPPERING} ? $r->{GRUPPERING} : $r->{DOMENE}) . '/' . $filename;
            $nr->{password} = $r->{PASSORD};
            $nr->{username} = $r->{BRUKER};
            $nr->{url}      = $r->{URL};
            $nr->{changed}  = $r->{BYTTE};
            $nr->{comment}  = $r->{BESKRIVELSE};
            $nr->{dir}      = $args->{dir} if $args->{dir};

            if ($nr->{filepath} =~ /jobb|Business/i) {
                $nr->{filepath} = basename($nr->{filepath});
                push @work_formated_data, $nr;
            }
            else {
                if (!exists $nr->{filepath} || !$nr->{filepath}) {
                    p $nr;
                    p $r;
                    die "Missing file path";
                }
                push @formated_data, $nr;
            }
        }
    }

    say "***";
    for my $f (@formated_data) {
        $self->_check_duplicate_and_store_file($f, $args);
    }
    say "****";
    $DB::single = 2;
    my %tmpargs = %$args;
    $tmpargs{dir} = $ENV{HOME} . '/' . '.password-store-work';
    for my $f (@work_formated_data) {
        $self->_check_duplicate_and_store_file($f, \%tmpargs);
    }

#    p @formated_data;
#    ...;
    # PRODUCE PASS CODE
    # [password]
    # filepath:
    # changed:  YYYY.MM.DD
    # username:
    # url:
    # comment:
    # extra:

    # die "Missing argument file" . encode_json($args) if ! $args->{file};
    # DumpFile($args->{file}, $data);
}

# _check_duplicate_and_store_file ($self, $f, $args)
# Internal method for checking if passord is a duplicate and handle what to do

sub _check_duplicate_and_store_file ($self, $f, $args) {
    if (!$f->{filepath}) {
        say "---";
        p $f;
        die "Missing filepath";
    }
    my $ex = SH::PassCode::File->from_file($f->{filepath}, $args);
    if ($ex) {

        # check if nothing is changed if so next else ask user.
        my $diff = 0;
        for my $k (SH::PassCode::File->okeys) {
            if ($f->{$k} && $ex->{$k} ne $f->{$k}) {
                $diff = 1;
                last;
            }
        }
        return if (!$diff);    # next $f
        say "Duplicate filename: " . $f->{filepath};
        if ($ex->{changed} && $f->{changed}) {
            if ($ex->{changed} gt $f->{changed}) {
                say "The existing has newest changed value. Recommend to choose [1] below";
            }
            elsif ($ex->{changed} lt $f->{changed}) {
                say "The last entry hasnewest changed value. Recommend to choose [2] below";
            }
        }

        say '[1]';
        p $ex;
        say "\n[2]";
        p $f;
        my $keep = ask('Which one do you want to keep? [1, 2, b=both, e=edit-file-2, q=quit]: ', [1, 2, 'b', 'e', 'q']);
        if ($keep eq 'q') {
            say "User exit";
            exit;
        }
        elsif ($keep eq '1') {
            return;    #ignore the last one
        }
        elsif ($keep eq '2') {

            # Continue. This will update the existing
        }
        elsif ($keep eq 'b') {
            $f->{filepath} .= "-" . $f->{username};
            if (SH::PassCode::File->from_file($f->{filepath}, $args)) {

                # new filename exists. Ask user what to do again.
                ...;
            }
        }
        elsif ($keep eq 'e') {
            my $old = basename($f->{filepath});
            my $dir = dirname($f->{filepath});
            say "Keep both. Alter the last entry $old";
            my $new = ask("Enter new filename old is $old: ", qr/.*/);
            if (!$new) {
                say "Do not know what to do. Cancel Redo something else?";

                # Cancel? Redo?
                ...;
            }
            $f->{filepath} = ($dir ? $dir . '/' : '') . $new;
            say "New filename is " . $f->{filepath};
        }
        else {
            die "Wrong input";
        }


        # enrich
        for my $k (SH::PassCode::File->okeys) {

            if ($f->{$k}) {
                my $x = $f->{$k};
                $ex->$k($x);
            }
        }
        $ex->to_file;
    }
    else {
        # Save new password
        # p $f;
        # die;
    #            $DB::single = 2;
        my $x = SH::PassCode::File->new(%$f)->to_file($args);

        #           p $x;
    }
} 1;
