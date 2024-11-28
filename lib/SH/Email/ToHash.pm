package SH::Email::ToHash;

use Mojo::Base -base;
use Data::Printer;
use Data::Dumper;
use Mojo::File 'path';
use MIME::Base64;
use Carp 'confess';

#use MIME::Charset;
use MIME::QuotedPrint;
use Clone 'clone';
use open OUT => ':encoding(UTF-8)';
use utf8;
use Encode;
has tmpdir => '/tmp';    # A lot of files will be generated.

# has parser => sub {
#     my $self = shift;
#     my $x    = MIME::Parser->new;
#     path($self->tmpdir)->make_path;
#     $x->output_dir($self->tmpdir);
#     $x;
# };

=encoding UTF-8

=head1 NAME

SH::Email::ToHash - convert raw email mime text to a nice hash

=head1 SYNOPSIS

    use SH::Email::ToHash;
    use Data::Dumper;
    print Dumper SH::Email::ToHash::message2hash('From: x\@y.c\nTo: d\@f.b');
    my $email = SH::Email::ToHash->new();
    print Dumper $email->message2hash("From: x\@y.c\nTo: d\@f.b");

=head1 DESCRIPTION

Export one function to convert raw-email-mime to a nice hash.

=head1 METHODS

=cut


=head2 msgtext2hash

Takes message number and return a hashref

return value {head=>{From=>'...', To=>'...'},body=>{Content-Type=>['text/plain',['charset=iso-8859-1']
Content-Transfer-Encoding=> quoted-printable},message =>{...}}

=cut

sub msgtext2hash {
    my $self   = shift;
    my $msg    = shift || return;
    my $return = {};

    #print @$msg;
#    my $email  = $self->parser->parse_data($msg);

    $msg =~ s&\r&&g;
    my ($header, $body) = split /\n\n/, $msg, 2;

#    say $header;
#
    $return->{header} = $self->parameterify($header);

    #remove first and last line
    my @body_cont = split /\n/, $body;
    if ($body_cont[0] =~ /^\-\-/) {
        $body = '';
        for my $i (1 .. ($#body_cont - 1)) {
            $body .= $body_cont[$i] . "\n";
        }
    }

    #warn $body;
    #warn "###############################################################";
    # TODO: Handle multipart
    if (exists $return->{header}->{'Content-Type'}) {
		if (! ref $return->{header}->{'Content-Type'}) {
			$body = {content => $body};
			$body->{'Content-Type'} = $return->{header}->{'Content-Type'};
		}
        elsif (exists $return->{header}->{'Content-Type'}->{a}
            && $return->{header}->{'Content-Type'}->{a}->[0] =~ /^multipart/) {
            $body = $self->multipart($return->{header}->{'Content-Type'}, $body);    # split or extract body part.
        }
        elsif ($return->{header}->{'Content-Type'}->{a}->[0]
            && (!ref $body || !exists $body->{'Content-Type'} || !$body->{'Content-Type'})) {
            $body = {content => $body};
            $body->{'Content-Type'} = $return->{header}->{'Content-Type'};
        }
    }
    if (   exists $return->{header}->{'Content-Transfer-Encoding'}
        && $return->{header}->{'Content-Transfer-Encoding'}
        && (!ref $body || !exists $body->{'Content-Transfer-Encoding'} || !$body->{'Content-Transfer-Encoding'})) {
        if (!ref $body) {
            $body = {content => $body};
        }
        $body->{'Content-Transfer-Encoding'} = $return->{header}->{'Content-Transfer-Encoding'};
    }
    if (!ref $body) {
        $return->{body} = $self->parameterify($body);
    }
    else {
        $return->{body} = $body;
    }
    $return = $self->hash_traverse(
        $return,
        sub {
            my ($v, $k) = @_;
            if ($v && !ref $v) {
                if ($v =~ /^\=.*\?\=/ || $k eq 'content') {
                    $v =~ s/\=\?iso\-8859\-1\?Q\?(.+)\?\=/decode_qp($1)/ige;
                    $v =~ s/\=\?iso\-8859\-1\?B\?(.+)\?\=/decode_base64($1)/ige;
                    $v =~ s/\=\?UTF-8\?B\?(.+)\?\=/decode('UTF-8',decode_base64($1))/ige;
                    $v =~ s/\=\?UTF-8\?Q\?(.+)\?\=/decode('UTF-8',decode_qp($1))/ige;
                }
                return ($v, 'next');
            }
            elsif (defined $k && $k eq 'body' && exists $v->{'Content-Type'} && $v->{'Content-Type'}) {
                if (ref $v->{'Content-Type'} eq 'HASH' && $v->{'Content-Type'}->{a}->[0] =~ /^multipart/i) {
                    $v->{content} = $self->multipart($v->{'Content-Type'}, $v->{body});
                }
                else {
                    if ($v->{'Content-Transfer-Encoding'}) {
                        if (lc $v->{'Content-Transfer-Encoding'} eq 'quoted-printable') {
                            $v->{content} = decode_qp($v->{content});
                        }
                        elsif (lc $v->{'Content-Transfer-Encoding'} eq 'base64') {
                            $v->{content} = decode_base64($v->{content});
                        }
                        elsif (lc $v->{'Content-Transfer-Encoding'} eq '7bit') {

                            # plain ASCII. Do notthing.
                        }
                        elsif (lc $v->{'Content-Transfer-Encoding'} eq '8bit') {

                            # nonstandard but probably latin1 do nothing, until problems
                        }

                        else {
                            warn "Unknown Content-Transfer-Encoding: " . $v->{'Content-Transfer-Encoding'};
                        }
                    }
                    elsif (ref $v->{'Content-Type'} && $v->{'Content-Type'}->{h}->{charset}  && uc $v->{'Content-Type'}->{h}->{charset} eq 'UTF-8') {
                        $v->{content} = decode('UTF-8', $v->{content});
                    }
#                    elsif (! ref $v->{'Content-Type'} && $v->{'Content-Type'} =~ /^multipart/i) {
#                        if ($type->{a}->[0] !~ /^multipart/) {
 #                       if (!exists $type->{h}->{boundary}) {
 #                       my $fake_type = clone $v;
 #                       $fake_type->{a} =[$v->{'Content-Type'}];
 #                       $v->{content} = $self->multipart($fake_type, $v->{body});
 #                   }
                    elsif (!ref $v->{'Content-Type'}) {
                        if (!grep { $v->{'Content-Type'} eq $_ } (qw|text/plain text/html|)) {
                            warn "Unknown simple Content-Type: " . $v->{'Content-Type'};
                            p $v;
                            die;
                        }
                    }
                    elsif (!grep { lc $v->{'Content-Type'}->{a}->[0] eq $_ } (qw|text/plain text/html|)) {
                        warn "Unknown Content-Type: " . Dumper $v->{'Content-Type'};    #$v->{'Content-Type'}->{a}->[0];
                    }
                    return ($v, 'next');    #next tree. Finish handling body hash tree
                }
            }
            return ($v, 'continue');        # continue traverse current tree
        }
    );

    return $return;
}

=head2 parameterify

Mime Email to hash
Takes a list of strings and concatenate them.


split on ;

Look for : Before the sign will be hash and after will be value.

No : will be an array item

return a perl data structure

=cut

sub parameterify {
    my $self = shift;
    return if !defined $_[0];
    my $string    = join('', @_);
    my $return    = {};
    my $multiline = 0;
    my $k;
    my $prev_l;
    for my $l (split(/\n/, $string)) {
        if ($multiline) {
            $return->{content} .= $l . "\n";
        }
        elsif ($l =~ /^([\w\-]+):\s(.*)$/) {
            $k = $1;
            my $v = $2;

            if (!exists $return->{$k}) {
                $return->{$k} = $v;
            }
            elsif (ref $return->{$k} eq 'ARRAY') {
                push @{$return->{$k}}, $v;
            }
            else {
                $return->{$k} = [$return->{$k}];
                push @{$return->{$k}}, $v;
            }
        }
        elsif ($l =~ /^\s+/) {
            if ($l =~ /^\s+$/ && ! $multiline ) {
                $multiline = 1;
                next;
            }
            elsif (! defined $k) {
                confess 'ERROR LINE: \''.$l."\'\nprevline: '$prev_l'";
            }
            if (ref $return->{$k} eq 'ARRAY') {
                $return->{$k}->[$#{$return->{$k}}] .= "\n" . $l;
            }
            else {
                $return->{$k} .= "\n" . $l;
            }
        }
        elsif ($l =~ /^([\w\-]+):$/) {
            $k = $1;
            $return->{$k} = undef;

        }
        elsif (!$l) {
            $k         = undef;
            $multiline = 1;
        }
        elsif ($l =~ /^\-\-\_.+\_$/) {
            $k = undef;
        }
        else {
            next if !defined $l;

            #warn $l;
            # handle unix email box header
            if ($l =~ /^From / && scalar keys %$return == 0) {
                $return->{heading} .= $l;
            }
            elsif ($l =~ /^([\w\-]+):(\S.*)$/) {
#                    $return->{error_header} .= $l;
                    $k = $1;
                    my $v = $2;

                    if (!exists $return->{$k}) {
                        $return->{$k} = $v;
                    }
                    elsif (ref $return->{$k} eq 'ARRAY') {
                        push @{$return->{$k}}, $v;
                    }
                    else {
                        $return->{$k} = [$return->{$k}];
                        push @{$return->{$k}}, $v;
                    }
                }
            }
            else {
                #Normal multilinestart
                $multiline = 1;
            }

            #...;
        }
        $prev_l = $l // '';
    }

#$return = $self->hash_parse_values($return, sub {my ($value)=@_;if ($value && $value=~/\;/sm) {return {a=>[split(/\;/,$value)]} };$value} );
    $return = $self->hash_traverse(
        $return,
        sub {
            my ($value, $key) = @_;

            # Do not split Subject if ; is in the header
            if ($key && $key eq 'Subject') {
                return ($value, 'continue');
            }

            # Make Array
            if ($value && ref $value eq '' && $key ne 'content' && $value =~ /\;/sm && $value !~ /^[^"]*\"[^"]*\;.*\"/) {
                return ({a => [split(/\;/, $value)],}, 'next');
            }
            return ($value, 'continue');
        }
    );

    $return = $self->hash_traverse(
        $return,
        sub {
            my ($v, $key) = @_;
            if (ref $v eq 'HASH' && exists $v->{a} && ref $v->{a} eq 'ARRAY') {
                for my $i (reverse 0 .. $#{$v->{a}}) {
                    if ($v->{a}->[$i] =~ /^\s*([\w\-\_\s\(\)]+)\=(.*)\s*/sm) {
                        my ($k, $val) = ($1, $2);
                        $v->{h}->{$k} = $val;
                        delete $v->{a}->[$i];
                    }
                }
                if (!@{$v->{a}}) {
                    delete $v->{a};
                }
                return ($v, 'next');    #next branch (stop travase further down)
            }
            return ($v, 'continue');    #continue looking further down in tree
        }
    );

#$return = $self->hash_parse($return, sub {my ($self,$value)=@_;if ($value=~/\;/sm) {return {a=>[split(/\;/,$value)]} }};$value );
    return $return;
}

=head2 hash_traverse

Traverse a data structure. (Depth first).

Takes self, data structure, anonymous subroutine, optional key

Subroutine is called for each item, including parents. Sub routine must return a (data structure, or value if item is a leaf) and a status.
(If status is next rest of the current branch traverse is stopped, and jump to next branch).

Returns a data structure.

=cut

sub hash_traverse {
    my $self = shift;
    my $hash = clone shift;
    my $sub  = shift;
    my $key  = shift;
    my ($x, $status) = $sub->($hash, $key);
    if ($status eq 'next') {
        return $x;
    }

    if (ref $hash eq 'HASH') {
        while (my ($k, $v) = each %$hash) {
            $hash->{$k} = $self->hash_traverse($v, $sub, $k);
        }
    }
    elsif (ref $hash eq 'ARRAY') {
        for my $i (0 .. $#{$hash}) {
            $hash->[$i] = $self->hash_traverse($hash->[$i], $sub, 'ARRAY');
        }
    }
    return $hash;
}

=head2 extract_emailaddress

Takes a typical From element and extract emailaddress

=cut

sub extract_emailaddress {
    my $self = shift;
    my $from = shift;
    return if !$from;
    RETRY:
    if (ref $from eq 'ARRAY') {
        ($from) = grep {index($_,'@')>=0} @$from;
    } elsif (ref $from eq "") {
    }elsif (ref $from eq 'HASH') {
        if (keys %$from == 1) {  # example of {a=>[]}
            $from = (values %$from)[0];
        }
        else {
            p $from;
            ...;
        }
    } else {
        warn "ref \$from is a ". ref($from);
        p $from;
        ...;
    }
    die "Cant find email address" if !$from =~ /\@/;
    if ($from =~ /\<([\w\.\_\-\+]+\@[\w\.\_\-]+)>/) {
        return $1;
    }
    return $from;
}

=head2 multipart

Handle MIME multipart body.

Expect content-type full and body (part)

=over 2

=item multipart/mixed

Return first part

=item  multipart/alternative

Choose simplest to traverse

=item multipart/digest

Die not handled

=item multipart/parallel

die not handled

=back

=cut

sub multipart {
    my ($self, $type, $body) = @_;
    my $return;
    die "Content-Type is not referanse $type\n" if ref $type ne 'HASH';
    if ($type->{a}->[0] !~ /^multipart/i) {
        die "Content-Type not like multipart\n".Dumper $type;
    }

    if (!exists $type->{h}->{boundary}) {
        p $body;
        say '';
        p $type;
        die "Missing boundary in Content-Type";
    }

    my $boundary = $type->{h}->{boundary};
    my $tmptype = lc($type->{a}->[0]);
    if (   $tmptype eq 'multipart/alternative'
        || $tmptype eq 'multipart/mixed'
        || $tmptype eq 'multipart/related') {

        #choose first which is usually easy to traverse
        return if !$body;
        my $rest = $body;
        ($body, $rest) = split /$boundary/, $rest, 2;

        if (!defined $body || $body !~ /\w/) {    # Discard empty alternatives

#            die join("\n\n", !!$body, !!$rest);
            (undef, $body) = split /$boundary/, $rest, 2;
        }
        return $body;
    }
    elsif ($tmptype eq 'multipart/report') {

        # ignore it for now
        return;
    }
    elsif ($tmptype eq 'multipart/digest') {
        ...;
    }
    elsif ($tmptype eq 'multipart/parallel') {
        ...;
    }
    else {
        warn "Unhandeled multidocument multipart $type->{a}->[0]";
        p $body;
        ...;
    }
    die;
}

=head1 AUTHOR

Slegga

=cut

1;
