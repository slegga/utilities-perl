use Test::More;
use Mojo::Base -strict;
use SH::Email::ToHash;
use Data::Dumper;
use Mojo::File 'path';

my $x = SH::Email::ToHash->new;
my $txt = <<'END_MESSAGE';
From root  Sun Mar 15 09:32:20 2020
Return-Path: <norwegian@mailgb.custhelp.com>
Content-Type: Multipart/Alternative;
  boundary="------------Boundary-00=_OP78VA40000000000000"
From: "Norwegian Customer Relations"
    <customer.relations@norwegian.com>
Reply-To: "Norwegian Customer Relations"
    <customer.relations@norwegian.com>
To: steihamm@online.no
Date: Sun, 15 Mar 2020 09:32:12 +0100 (CET)
Subject: Cancelled flight claim for booking reference MJGH76 - Flight  DY1817 LPA-OSL 24.02.20 [Incident: 200307-001033]
END_MESSAGE

#die Dumpe r $x->parameterify($txt);
is_deeply ($x->parameterify($txt)->{'Content-Type'}, {a=>['Multipart/Alternative'],h=>{boundary=>'"------------Boundary-00=_OP78VA40000000000000"'}});

# use Test::Deep;
 path 't/problememails';
for my $f(path('t/data')->list->each) {
    next if $f->to_string !~ /\.txt$/;
    my $cont =$x->msgtext2hash($f->slurp);
    ok(exists $cont->{header}->{'Content-Type'},$f->to_string);
    like ($cont->{header}->{From}, qr'(no|com|shop)','from');
}
# exists $msg->{'Content-Type'}
# ...; # TODO:


done_testing;