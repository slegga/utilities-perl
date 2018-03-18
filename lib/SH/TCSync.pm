package SH::TCSync;

=encoding utf8

=head1 NAME

SH::TCSync - Common methods for handling tc files.

=head1 SYNOPSIS

use SH::TCSync qw(tcsync);
tcsync()


=head1 DESCRIPTION

Synchronize between catalogs and dropbox encrypted file.
Remove duplicated files if any.

=cut

use Carp;
use Data::Dumper;
use autodie;
use Mojo::Base -strict;
use YAML::Tiny;
use IPC::System::Simple qw(system);
use File::Basename;
use File::Find;
use File::Compare;
use File::Copy qw(move copy);
use FindBin;
use List::MoreUtils qw(uniq any);
use utf8;
use Exporter 'import';
our @EXPORT_OK = qw(mount unmount tcsync fix_duplicated_tcfiles);

our $homedir;
# our $passworddir;
# our $keyfiledir;
# our $trueprog;
# our $tcoptions;
# our $dirsep;
# our $clear;
my $passwordfile = 'passord3';
my $igoreddirs_rx;
my $basedir;
my $files_hr;

BEGIN {
    push @INC, "$FindBin::Bin/../lib";
    if ( $^O eq 'MSWin32' ) {
        $homedir     = 'c:\privat';
    } else {
        $homedir     = $ENV{HOME};
    }
}

my $configfile = ($ENV{CONFIG_DIR}||$ENV{HOME}.'/etc').'/SH-TCSync.yml';
my $config = YAML::LoadFile($configfile);

use SH::ArrayCompare;
say $SH::ArrayCompare::VERSION;
SH::ArrayCompare::compare_arrays('a', ['a','b'], ['b','c']);

use SH::Script qw(ask);

my $passworddir = $config->{passworddir};
my $trueprog    = $config->{truecrypt};
my $dirsep      = $config->{dirsep};
my $tcoptions   = $config->{tcoptions};

my @igoredfiles = ('.kate-swp');
my $dropbox='/usr/bin/dropbox';
#
#   SUBROUTINES
#

=head1 FUNCTIONS

=head2 mount

Mount a tc-file. Put it in an array

=cut

sub mount {
    my $tcfile     = shift;
    my $mountdirno = shift;
    unmount($mountdirno);
    my $out;
    my $tcdirname  = dirname($tcfile);
    my $tcbasename = basename($tcfile);
    $tcbasename = quotemeta($tcbasename);
    if ( $^O eq 'MSWin32' ) {

        #warn $tcbasename;
        $tcbasename =~ s/\\\././g;
    }

    $out = sprintf "$trueprog $tcoptions %s %s", $tcdirname . $dirsep . $tcbasename, $passworddir->[$mountdirno];

    # http://www.dropboxwiki.com/tips-and-tricks/using-the-official-dropbox-command-line-interface-cli
    for my $i (0 .. 10) {
        my $output = `$dropbox status`;
        chomp $output;
        if ( $output ne "Up to date" && $output ne 'Oppdatert' ) {
            print "\nOUTPUT: $output\n$out\n";
            sleep 4;
            next
#            die "Dropbox is not up to date. PLEASE TRY AGAIN LATER!";
        }
        last;
    }
    system($out) and confess"Syserror: ".$out.' '.$@; #0 = ok other is error
}

=head2 unmount

Un mount a tc-file.

=cut

sub unmount {
    my $mountdirno = shift;
    if ( -d $passworddir->[$mountdirno] ) {
        print "unmount $mountdirno\n";

        my $out =
            "$trueprog "
            . (
            $^O eq 'MSWin32' ? '/q /d ' . substr( $passworddir->[$mountdirno], 0, 1 ) : '-d ' . $passworddir->[$mountdirno] );
        system($out) and confess"Syserror: ".$out.' '.$@; #0 = ok other is error
    }
}

=head2 tcsync

Sync between local files and tc file for distribution of common files

=cut

sub tcsync {

    #
    #   copy files from nx-mysql
    #
    if ( $^O ne 'MSWin32' && getpwuid($<) eq 't527081' ) {
        `rsync dev-prod1:/local/net/experimental/t527081/git/nx-mysql/lib/Nx/SQL/Script.pm $passworddir->[0]/lib/Nx/SQL/.`;
        `rsync dev-prod1:/local/net/experimental/t527081/git/nx-mysql/lib/Nx/SQL/ArrayCompare.pm $passworddir->[0]/lib/Nx/SQL/.`;
        `rsync dev-prod1:/local/net/experimental/t527081/git/nx-mysql/lib/Nx/SQL/Logf.pm $passworddir->[0]/lib/Nx/SQL/.`;
        `rsync dev-prod1:/local/net/experimental/t527081/git/nx-mysql/lib/Nx/SQL/Utils.pm $passworddir->[0]/lib/Nx/SQL/.`;
        `rsync dev-prod1:/local/net/experimental/t527081/git/nx-mysql/lib/Nx/SQL/ScriptTest.pm $passworddir->[0]/lib/Nx/SQL/.`;
        `rsync dev-prod1:/local/net/experimental/t527081/git/nx-mysql/lib/Nx/SQL/ResultSet.pm $passworddir->[0]/lib/Nx/SQL/.`;
        `rsync dev-prod1:/local/net/experimental/t527081/git/nx-mysql/lib/Nx/SQL/Dot.pm $passworddir->[0]/lib/Nx/SQL/.`;
        `rsync dev-prod1:/local/net/experimental/t527081/git/nx-mysql/script/systest.pl $passworddir->[0]/bin`;
        `rsync dev-prod1:/local/net/experimental/t527081/git/nx-mysql/script/spellchecker $passworddir->[0]/bin`;
        `rsync dev-prod1:/local/net/experimental/t527081/data/systests/0* $passworddir->[0]/data/systests`;
        `rsync dev-prod1:/home/t/t527081/.personaldictionary.txt /home/t527081/.`;
        `rsync dev-prod1:/home/t/t527081/.perltidyrc /home/t527081/.`;
    }
    #
    #   Sync with veracrypt
    #

    my $db_files_hr = {};
    my $pc_files_hr = {};

    #my $acceptedfiles_rx=qr/(\.pl|\.pm)$/;
    $igoreddirs_rx = qr/(?:Perl-Tidy-20101217|\.sh$|\.css$|\.ptkdb|\.png|\.bak|\.tdy|dropbox.py|\.perltidyrc$)/;
    $files_hr      = $db_files_hr;                                             #ugly work around passing arguments
    $basedir       = $passworddir->[0];                                        #ugly work around passing arguments

    find( \&_wanted_tcsync, $passworddir->[0] . '/bin', $passworddir->[0] . '/lib', $passworddir->[0] . '/t', $passworddir->[0] . '/data' );
    %$db_files_hr = %$files_hr;

    $files_hr = $pc_files_hr;                                                  #ugly work around passing arguments
    $basedir  = $homedir;                                                      #ugly work around passing arguments
    find( { wanted => \&_wanted_tcsync, follow_fast => 1 }, $homedir . '/bin', $homedir . '/lib', $homedir . '/t',  $homedir . '/data');
    %$pc_files_hr = %$files_hr;

    my ( $dbfiles_only, $commonfiles, $pcfiles_only );

    my @db_fnames = keys %$db_files_hr;
    my @pc_fnames = keys %$pc_files_hr;
    @db_fnames = sort @db_fnames;
    @pc_fnames = sort @pc_fnames;

    my $db_fnames_ar = \@db_fnames;
    my $pc_fnames_ar = \@pc_fnames;
    ( $dbfiles_only, $commonfiles, $pcfiles_only ) = SH::ArrayCompare::compare_arrays( 'a', $db_fnames_ar, $pc_fnames_ar );
    if (@$dbfiles_only) {
        print "Dropbox only\n" . Dumper $dbfiles_only;
    }

    #print "common files\n".Dumper $commonfiles;
    if (@$pcfiles_only) {
        print "Localfiles only\n" . Dumper $pcfiles_only;
    }

    for my $file (@$commonfiles) {
        next if any { $file =~ /$_/ } @igoredfiles;
        if ( compare( $homedir . '/' . $file, $passworddir->[0] . '/' . $file ) != 0 ) {
            my $pc_mtime = ( stat( $homedir . '/' . $file ) )[9];
            my $db_mtime = ( stat( $passworddir->[0] . '/' . $file ) )[9];
            print "DIFFER: $file ";
            if ( $pc_mtime > $db_mtime ) {
                print "Replace DropBox version\n";
                copy( $homedir . '/' . $file, $passworddir->[0] . '/' . $file );
            } elsif ( $pc_mtime < $db_mtime ) {
                print "Local file will be replaced\n";
                copy( $passworddir->[0] . '/' . $file, $homedir . '/' . $file );
            } else {
                print "Equal dataes please investigate!\n";
            }

            #print "diff $homedir/$file $passworddir/$file\n";
            #`diff $homedir/$file $passworddir/$file`;

        }
    }

    for my $file (@$dbfiles_only) {
        next if any { $file =~ /$_/ } @igoredfiles;
        print "Copy $file from DropBox\n";
        my $dirname    = dirname( $homedir . '/' . $file );
        my $tmpdirname = $dirname;

        #make dir path if not exists
        while ( !-d $tmpdirname ) {
            my $reallytmp = $tmpdirname;
            $reallytmp =~ s/\/[\w\.]+$//;
            if ( !-d $reallytmp ) {
                $tmpdirname = $reallytmp;
            }
            print "mkdir($tmpdirname)\n";
            mkdir($tmpdirname);
            $tmpdirname = $dirname;
            next;
        }
        copy( $passworddir->[0] . '/' . $file, $homedir . '/' . $file )
            || die "Could not copy($passworddir->[0].'/'.$file, $homedir.'/'.$file)";
    }

}

sub _wanted_tcsync {
    if ( -f $File::Find::name ) {
        return if $File::Find::name =~ $igoreddirs_rx;
        my $key = $File::Find::name;
        $key =~ s/^$basedir\///;
        $files_hr->{$key} = $File::Find::name;
    }
}

my @fullfilenames;

sub _wanted_clean {
    if ( -f $_ ) {
        push @fullfilenames, $File::Find::name;
    }
}

=head2 fix_duplicated_tcfiles

Handles when dropbox makes duplicated files because of slow updates or editing same tc file at once.

=cut

sub fix_duplicated_tcfiles {
    my $tcglob = shift;
    confess "\$tcglog is undef" if ( !defined $tcglob || $tcglob eq '' );
    $tcglob =~ s:\.:\*:;

    my @duplicatedfiles = glob($tcglob);
    if ( @duplicatedfiles == 0 ) {
        confess "Missing password file $tcglob";
    } elsif ( @duplicatedfiles > 1 ) {
        _clean_old_pwdfiles(@duplicatedfiles);
        print "Kjør på nytt ...\n";
        exit;
    }
}

sub _clean_old_pwdfiles {
    my @duplicatedfiles = sort { get_date_from_filename($a) cmp get_date_from_filename($b) } @_;
    print "Has to clean up duplcated files. Then rerun script.";
    print "\n", join( "\n", @duplicatedfiles ), "\n";
    my $deleted = 0;
    for my $i ( 0 .. ( $#duplicatedfiles - 1 ) ) {
        my @files = ();
        for my $j ( 0 .. 1 ) {
            mount( $duplicatedfiles[ $i + $j ], $j );
            @fullfilenames = ();
            find( \&_wanted_clean, $passworddir->[$j] );
            for my $fullname (@fullfilenames) {
                my $thisname = substr( $fullname, length( $passworddir->[$j] ) + 1 );
                my ( $dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks ) =
                    stat($fullname);
                $files[$j]->{$thisname}->{size}     = $size;
                $files[$j]->{$thisname}->{fullname} = $fullname;
                print join( ', ', $j, $thisname, $mode, $nlink, $rdev, $size, $atime, $mtime, $ctime, $blocks ), "\n";
            }
        }
        # Hvis første fil er tom.
        check_delete_empty_tc_files( $duplicatedfiles[ $i + 0 ], 0 );

        #SAMMENLIGN HER STØRRELSE PÅ SAMME FIL. HVIS LIK SLETT ELDSTE
        for my $diffname ( keys %{ $files[0] } ) {
            if ( !exists $files[1]->{$diffname} ) {
                check_delete_empty_tc_files( $duplicatedfiles[ $i + 1 ], 1 );
            } else {
                if ( $files[0]->{$diffname}->{size} == $files[1]->{$diffname}->{size} ) {
                    my $answer =
                        ask( "$diffname Filene er like store. Slette " . ( $files[0]->{$diffname}->{fullname} // 'undef' ),
                        [ 'y', 'n' ] );
                    if ( $answer eq 'y' ) {
                        unlink( $files[0]->{$diffname}->{fullname} );
                        $deleted = 1;
                        check_delete_empty_tc_files( $duplicatedfiles[ $i + 0 ], 0 );
                    } else {
                        exit;
                    }
                }
            }
        }

        # TODO BE OM Å LAGE CSV FIL FOR ALLE FILER SOM IKKE SLUTTER PÅ CSV

        #ELLERS BEHOLD FILENE OG SKRIV UT MELDING OM Å LAGE EN CSV FIL SOM KAN BRUKES TIL DIFFING
        for my $diffname ( keys %{$files[0]} ) {
            next if $diffname !~ /\.csv/i;
            next if !exists $files[1]->{$diffname};
            my $csvname = $diffname;
            $csvname =~ s/\.\w{3}/\.csv/;
#             while ( !-f $passworddir->[0] . '/' . $csvname || !$deleted ) {
#                 ask( $passworddir->[0] . '/' . $csvname . " finnes ikke. Lag denne filen med data og trykk en tast:1" );
#             }
            next if( !-f $passworddir->[0] . '/' . $csvname || !$deleted );
            while ( !-s $passworddir->[0] . '/' . $csvname ) {
                ask( $passworddir->[0] . '/' . $csvname . " er tom legg inn riktig data i filen og trykk en tast:1" );
            }
            while ( !-f $passworddir->[1] . '/' . $csvname ) {
                ask( $passworddir->[1] . '/' . $csvname . " finnes ikke. Lag denne filen med data og trykk en tast:2" );
            }
            while ( !-s $passworddir->[1] . '/' . $csvname ) {
                ask( $passworddir->[1] . '/' . $csvname . " er tom legg inn riktig data i filen og trykk en tast:2" );
            }
            my @filebody = ();
            for my $k ( 0 .. 1 ) {
                open my $fh, '<', $passworddir->[$k] . '/' . $csvname;
                my @tmp = sort <$fh>;
                $filebody[$k] = \@tmp;
                close $fh;
            }
            my ( $onlyold, undef, $onlynew ) =SH::ArrayCompare::compare_arrays( 'a', $filebody[0], $filebody[1] );
            @$onlyold = grep {/\w/} uniq @$onlyold;
            print "\nONLY IN OLD " . $duplicatedfiles[ $i + 0 ] . ":\n";
            print join( "\n", @$onlyold );
            print "\n\nONLY IN NEW " . $duplicatedfiles[ $i + 1 ] . ":\n";
            print join( "\n", grep {/\w/} @$onlynew );
            while (1) {

                if ( !@$onlyold ) {
                    my $answer = ask(
                        "Filen "
                            . $passworddir->[0] . '/'
                            . $csvname
                            . " innehold ikke unike rader. Vil slette denne og "
                            . $passworddir->[0]
                            . $diffname,
                        [ 'y', 'n' ]
                    );
                    if ( $answer eq 'y' ) {
                        unlink( $files[0]->{$diffname}->{fullname} );
                        unlink( $passworddir->[0] . '/' . $csvname );
                        check_delete_empty_tc_files( $duplicatedfiles[ $i + 0 ], 0 );
                    } else {
                        exit;
                    }
                    last;
                } else {
                    my $answer = ask( 'Vil du overføre savnede rader til ny ' . $csvname . ' fil og slette den gamle?',
                        [ 'y', 'slett', 'n' ] );
                    if ( $answer eq 'y' ) {
                        open my $fh, '>>', $passworddir->[1] . '/' . $csvname;
                        for my $row (@$onlyold) {
                            print $fh $row;
                        }
                        close $fh;
                        unlink( $files[0]->{$diffname}->{fullname} );
                        unlink( $passworddir->[0] . '/' . $csvname );
                        check_delete_empty_tc_files( $duplicatedfiles[ $i + 0 ], 0 );
                    } elsif ( $answer eq 'slett' ) {
                        unlink( $files[0]->{$diffname}->{fullname} );
                        unlink( $passworddir->[0] . '/' . $csvname );
                        check_delete_empty_tc_files( $duplicatedfiles[ $i + 0 ], 0 );
                    } else {
                        exit;
                    }
                    last;
                }
            }

        }

        #DIFF CSV FILENE
        for my $diffname ( keys %{$files[0]} ) {
            next if $diffname !~ /\.csv/i;
            next if !exists $files[1]->{$diffname};
            my @filebody = ();
            for my $k ( 0 .. 1 ) {
                open my $fh, '<', $files[$k]->{$diffname}->{fullname};
                my @tmp = sort <$fh>;
                $filebody[$k] = \@tmp;
                close $fh;
            }
            my ( $onlyold, undef, $onlynew ) =SH::ArrayCompare::compare_arrays( 'a', $filebody[0], $filebody[1] );
            @$onlyold = grep {/\w/} uniq @$onlyold;
            print "\nONLY IN OLD " . $duplicatedfiles[ $i + 0 ] . ":\n";
            print join( "", @$onlyold );
            print "\n\nONLY IN NEW " . $duplicatedfiles[ $i + 1 ] . ":\n";
            print join( "", grep {/\w/} @$onlynew );
            while (1) {

                if ( !@$onlyold ) {
                    my $answer = ask(
                        "Filen "
                            . $files[0]->{$diffname}->{fullname}
                            . " innehold ikke unike rader. Vil slette denne og "
                            . $passworddir->[0]
                            . $diffname,
                        [ 'y', 'n' ]
                    );
                    if ( $answer eq 'y' ) {
                        unlink( $files[0]->{$diffname}->{fullname} );
                        check_delete_empty_tc_files( $duplicatedfiles[ $i + 0 ], 0 );
                    } else {
                        exit;
                    }
                    last;
                } elsif ( @$onlyold > 10 && @$onlynew > 10 ) {
                    print "Mye diff. Analyserer og finner ut om skilletegn er forskjellig\n";
                    my @skilletegn = ();
                    $skilletegn[0]->{'\t'} += ( $_ =~ /\t/ ) // 0 for @$onlyold;
                    $skilletegn[1]->{'\t'} += ( $_ =~ /\t/ ) // 0 for @$onlynew;
                    $skilletegn[0]->{'\,'} += ( $_ =~ /\,/ ) // 0 for @$onlyold;
                    $skilletegn[1]->{'\,'} += ( $_ =~ /\,/ ) // 0 for @$onlynew;
                    $skilletegn[0]->{'\;'} += ( $_ =~ /\;/ ) // 0 for @$onlyold;
                    $skilletegn[1]->{'\;'} += ( $_ =~ /\;/ ) // 0 for @$onlynew;
                    $skilletegn[0]->{real} = ( sort { $skilletegn[0]->{$a} <=> $skilletegn[0]->{$b} } keys %{$skilletegn[0]} )[-1];
                    $skilletegn[1]->{real} = ( sort { $skilletegn[1]->{$a} <=> $skilletegn[1]->{$b} } keys %{$skilletegn[1]} )[-1];

                    if ( $skilletegn[0]->{real} && $skilletegn[1]->{real} && $skilletegn[0]->{real} ne $skilletegn[1]->{real} )
                    {
                        print "Endrer skilletegn";
                        my $old = $skilletegn[0]->{real};
                        my $new = $skilletegn[1]->{real};
                        s/$old/$new/ for (@$onlyold);
                        @$onlyold = get_unmatched( 'a', @$onlyold, @$onlynew );
                    } else {
                        print "Går igjennom alle gamle rader som ikke finnes i ny og spør om rad skal flyttes over.\n";
                        print "Tilslutt slettes gammel fil.\n";
                        my @addedrows = ();

                        #warn join("",@$onlyold);
                        for my $oldrow (@$onlyold) {
                            my $topscore  = 0;
                            my $topstring = 'ERROR';

                            for my $newrow (@$onlynew) {
                                my $score = calculate_likeness_score( $oldrow, $newrow );
                                if ( $score > 65 ) {
                                    printf "%d:    %s", $score, $newrow;
                                }
                                if ( $score > $topscore ) {
                                    $topscore  = $score;
                                    $topstring = $newrow;
                                }
                            }

                            # for hver gammel rad spør legge til eller slett.
                            printf "Best: %d:  %s\n", $topscore, $topstring;
                            printf "Rad:                %s", $oldrow;
                            my $answer = ask( 'Beholde eller Slette', [ 'b', 's' ], { 'remember' => 1 } );
                            if ( $answer eq 'b' ) {
                                push @addedrows, $oldrow;
                            }
                        }
                        print "Overfører følgende:\n";
                        print join( "", @addedrows ), "\n";
                        ask( "Fortsette", ['y'], { exit_on_nochoice => 1 } );
                        open my $fh, '>>', $files[1]->{$diffname}->{fullname};
                        print $fh @addedrows;
                        close $fh;
                        ask( "Slette filen" . $files[0]->{$diffname}->{fullname}, ['y'], { exit_on_nochoice => 1 } );
                        unlink( $files[0]->{$diffname}->{fullname} );
                        check_delete_empty_tc_files( $duplicatedfiles[ $i + 0 ], 0 );
                        last;
                    }
                } else {
                    my $answer = ask( 'Vil du overføre savnede rader til ny ' . $diffname . ' fil og slette den gamle?',
                        [ 'y', 'slett', 'n' ] );
                    if ( $answer eq 'y' ) {
                        open my $fh, '>>', $files[1]->{$diffname}->{fullname};
                        for my $row (@$onlyold) {
                            print $fh $row;
                        }
                        close $fh;
                        unlink( $files[0]->{$diffname}->{fullname} );
                        check_delete_empty_tc_files( $duplicatedfiles[ $i + 0 ], 0 );
                    } elsif ( $answer eq 'slett' ) {
                        unlink( $files[0]->{$diffname}->{fullname} );
                        check_delete_empty_tc_files( $duplicatedfiles[ $i + 0 ], 0 );
                    } else {
                        exit;
                    }
                    last;
                }
            }

        }
        unmount(0);
        unmount(1);

    }
}

=head2 calculate_likeness_score

Calculate a likeness score between two strings.
Used to give a suggestion for a value when try to fix duplicates.

=cut

sub calculate_likeness_score {
    my $oldstring  = shift;
    my $newstring  = shift;
    my @oldchar    = sort split //, $oldstring;
    my @newchar    = sort split //, $newstring;
    my $lengthdiff = abs( length($oldstring) - length($newstring) );
    my ( $olduniq, $both, $newuniq ) =SH::ArrayCompare::compare_arrays( 'a', \@oldchar, \@newchar );
    my $score = @$both / ( @$olduniq + @$both + @$newuniq );
    $score = int( 100 * ( $score + 0.005 ) );
    return $score;
}

=head2 check_delete_empty_tc_files



=cut

sub check_delete_empty_tc_files {
    my $tcfile     = shift;
    my $mountdirno = shift;
    confess "Missing mount no" . ( $mountdirno // 'undef' ) if ( $mountdirno != 0 && $mountdirno != 1 );
    my @empfiles = glob( $passworddir->[$mountdirno] . '/*' );
    if ( !@empfiles ) {
        my $answer = ask( $tcfile . "\n" . $passworddir->[$mountdirno] . " er tom. Slette? ", [ 'y', 'n' ] );
        if ( $answer eq 'y' ) {
            unmount($mountdirno);
            unlink($tcfile);
            print "Stopper prosess. Rekjør" if $mountdirno == 1;
        }
        exit if $mountdirno == 1;
    }

}

=head2 get_date_from_filename

Returns the date of the file

=cut

sub get_date_from_filename {
    my $filenamed = shift;
    $filenamed =~ /(\d{4}\-\d\d\-\d\d)/;
    return $1 if ($1);
    return 9999 - 99 - 99;
}

=head1 AUTHOR

Stein Hammer

=cut

1;
