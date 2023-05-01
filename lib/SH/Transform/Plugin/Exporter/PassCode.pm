package SH::Transform::Plugin::Exporter::PassCode;
use Mojo::Base 'SH::Transform::Exporter',-signatures;
use Mojo::File 'path';
use Mojo::JSON qw/encode_json/;
use POSIX 'strftime';
use Data::Printer;
use SH::PassCode;



=head1 NAME

SH::Transform::Plugin::Exporter::PassCode - create files and fills them with pass code encrypted data.

=head1 SYNOPSIS

    use SH::Transform;
    my $trans = SH::Transform->new(Exporter=>SH::Transform::Plugin::Exporter::PassCode->new);
    $trans->transform({file=>'test.json'},{type=>'PassCode'});

=head1 DESCRIPTION

Enable export to yaml formated file.

=head1 METHODS

=head2 is_accepted

...

=cut

has passcode => sub {SH::PassCode->new};

sub is_accepted($self, $args) {
    return 1 if exists $args->{type} && lc($args->{type}) eq 'passcode';
    return 0;
}

sub export($self,$args,$data) {
    # TRANSFORM
    my @formated_data; # ({filepath,password,username,url,change,comment,{extra}})
    #if lastpass
    if(exists $data->[0]->{name} && $data->[0]->{name}) {

        # url,username,password,totp,extra,name,grouping,fav
        for my $r(@$data) {
            my $nr;
            
            $nr->{filepath} = $r->{grouping} ? $r->{grouping}."/".$r->{name} : $r->{name};
            for my $k(qw/ password username url/) {
                $nr->{$k} = $r->{$k};
            }
            $nr->{changed} = my $date = strftime '%Y-%m-%d', localtime;
            $nr->{comment} = $r->{extra};
            $nr->{comment} .= ',topt:'.$r->{topt} if $r->{topt};
            $nr->{comment} .= ',fav:'.$r->{topt} if $r->{fav};
            $nr->{dir} = $args->{dir} if $args->{dir};
            push @formated_data, $nr;
        }
        
    }
    elsif(exists $data->[0]->{SYSTEM}) {
        #if sqlite3
        ...;
        #select * from passord3 where 1=1 and ( 1=0  or SYSTEM regexp ? or URL regexp ? or BRUKER regexp ? or PASSORD regexp ? or BESKRIVELSE regexp ? ) ORDER BY SYSTEM,BRUKER
        # id  DOMENE SYSTEM                   URL                                             BRUKER                   PASSORD  BESKRIVELSE                  BYTTE 
    }

    for my $f (@formated_data) {
        my $ex = SH::PassCode::File->from_file($f->{filepath},$args);
        if ( $ex) {
            # enrich
            for my $k( SH::PassCode::File->keys ) {
                if ($f->$k) {
                    $ex->$k;
                }
            }
            $ex->to_file;
        } 
        else {
            my $x = SH::PassCode::File->new(%$f)->to_file;    
        }
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
1;