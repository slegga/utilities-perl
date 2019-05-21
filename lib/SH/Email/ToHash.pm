package SH::Email::ToHash;

use Mojo::Base -base;
use Data::Printer;
use Data::Dumper;
use MIME::Parser;
use MIME::Base64;

#use MIME::Charset;
use MIME::QuotedPrint;
use Clone 'clone';
use open OUT => ':encoding(UTF-8)';
use utf8;
use Encode;
has tmpdir => '/tmp';
has parser => sub { my $x = MIME::Parser->new; $x->output_dir(shift->tmpdir); $x };

=encoding UTF-8

=head1 NAME

SH::Email::RawToHash - convert raw email mime text to a nice hash

=head1 SYNOPSIS

    use SH::Email::RawToHash;
    use Data::Dumper;
    print Dumper SH::Email::RawToHash::message2hash("From: x@y.c\nTo: d@f.b");

=head1 DESCRIPTION

Export one function to convert raw-email-mime to a nice hash.

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
    my $email  = $self->parser->parse_data($msg);
    my $header = $email->head->stringify;

#    say $header;
#
    $return->{header} = $self->parameterify($header);
    my $body = $email->stringify_body;

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
    $return->{body} = $self->parameterify($body);
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
            elsif (defined $k
                && $k eq 'body'
                && exists $v->{'Content-Transfer-Encoding'}
                && exists $v->{'Content-Type'}) {
                if (lc $v->{'Content-Transfer-Encoding'} eq 'quoted-printable') {
                    $v->{content} = decode_qp($v->{content});
                }
                elsif (lc $v->{'Content-Transfer-Encoding'} eq 'base64') {
                    $v->{content} = decode_base64($v->{content});
                }
                elsif (lc $v->{'Content-Transfer-Encoding'} eq '7bit') {

                    # plain ASCII. Do notthing.
                }
                else {
                    warn "Unknown Content-Transfer-Encoding: " . $v->{'Content-Transfer-Encoding'};
                }

                if (lc $v->{'Content-Type'}->{h}->{charset} eq 'UTF-8') {
                    $v->{content} = decode('UTF-8', $v->{content});
                }
                elsif (lc $v->{'Content-Type'}->{a}->[0] ne 'text/plain') {
                    warn "Unknown Content-Type: " . Dumper $v->{'Content-Type'};    #$v->{'Content-Type'}->{a}->[0];
                }
                return ($v, 'next');    #next tree. Finish handling body hash tree
            }
            return ($v, 'continue');    # continue travarse current tree
        }
    );

    #$self->decode_mime_iso_8859_1_hash($return);

    #say $email->effective_type();

    #say$self->decode_mime_iso_8859_1($email->stringify_body);
    return $return;
}

=head2 parameterify

Mime Email to hash
Takes a list of strings and concatinate them.


split on ;

Look for : Before the sign will be hash and after will be value.

No : will be an array item

return a perl data structure

=cut

sub parameterify {
    my $self      = shift;
    my $string    = join('', @_);
    my $return    = {};
    my $multiline = 0;
    my $k;
    for my $l (split(/\n/, $string)) {
        if ($multiline) {
            $return->{content} .= $l . "\n";
        }
        elsif ($l =~ /^([\w\-]+):\s(.*)/) {
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
            next if !defined $k && $l =~ /^\s*$/;
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
            else {
                #Normal multilinestart
                $multiline = 1;
            }

            #...;
        }
    }

#$return = $self->hash_parse_values($return, sub {my ($value)=@_;if ($value && $value=~/\;/sm) {return {a=>[split(/\;/,$value)]} };$value} );
    $return = $self->hash_traverse(
        $return,
        sub {
            my ($value, $key) = @_;
            if ($value && ref $value eq '' && $key ne 'content' && $value =~ /\;/sm) {
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

Traverse a data structure. (Dept first).

Takes self, datastructure, anonymous subroutine, optional keys

Subroutine is called for each item, including parents. Sub routine must return a (datastructure, or value if item is a leaf) and a status.
(If status is next rest of the current branch travserse is stopped, and jump to next branch).

Returns a datastructure.

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

Takes a typial From element and extract emailaddress

=cut

sub extract_emailaddress {
    my $self = shift;
    my $from = shift;
    die "Cant find email address" if !$from =~ /\@/;
    if ($from =~ /\<([\w\.\_\-]+\@[\w\.\_\-]+)>/) {
        return $1;
    }
    return $from;
}

=head1 AUTHOR

Slegga

=cut

1;
