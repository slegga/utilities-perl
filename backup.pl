#!/usr/bin/perl
use warnings;
use strict;
use File::Copy;
use File::Path qw(make_path);
use autodie;
use Carp;
# Sist oppdaterte skal ligge på $HOME/bin
# Andre kopier skal ikke fore komme kun på backup disker.

#TODO:
# Lag kopi truecrypt disk basert på configfil
#Design backup.pl *.tc
#   skal for hver .tc fil i Backup katalogen:
#	Skal først sjekke at alt er ok og alle diskene skal mountes med passord fra prompt
#	så er det ikke mening med bruker interaktivitet før skriptet er ferdig
#   1. sjekke config-fullBackup.txt om fil finnes der
#   2. mounte
#   3.
#   4. avmounte
#   5. evt. kopiere til angitte drev/kataloger

####################################
#	START KODE
####################################
print "Starter backup prosessen.\n";

my @catalogsForBackup = ();
my ($BACKUPDISK,$PROJECT_HOME,$CONFIG,$FILLOG,$debug,$nocopy,$test,@backupFiles,@backupDisks);
my (@trueCryptDiskList);
my $osfilter=qr /([\@\w\/\~Ã¦Ã¸Ã¥Ã¶Ã»ÃÃÃ .&\+\,\#\*\=\~\%\)\(\[\]\{\}\'\Â´\?\!+-]+)/;
$PROJECT_HOME='/home/stein';
#####################################
#	SUBCODE
#####################################
sub usage {
print "backup.pl [-sjekk][-debug][-nocopy] *.tc\n\n";
print"Husk og koble til flyttbar og minnepenn. Og pass på at de er mounted\n";
print "For vanlig backup: \n";
print "sudo su;cd /home/stein/Backup \n";
print "clear;/home/stein/bin/backup.pl *.tc\n";
print "For korttids backup av arbeidsdokumenter: clear;backup.pl *.tct\n";
print "\nFor å etablere ny fil. Gjør følgende\n";
print "1. Lag en truecrypt fil på Backup området med passe med plass og passende navn. La den hete .tc på slutten\n";
print "2. Mount disken\n";
print "3. Skriv i Terminal vindu: gedit config-backup.txt\n";
print "4. Legg inn katalogene det skal tas backup av.\n";
print "5. Skal filen kopieres etter på så legg inn en eller flere kopi:/media/FLYTTBAR/sikkerhetskopi.\n";
print "6. Kjør clear;backup.pl *.tc\n";
print "7. Sjekk backup. Hvis ok så er du ferdig.\n\n";
print "[-sjekk]	        Kjører preprosessering. Stopper script før fil-operasjonene.\n";
print "[-nocopy]        Oppdaterer backup filene. Men kopierer ikke til eksterne mecroakr. Passer for backup av arbeidsfiler.\n";

exit;

}

sub hentTre {
	my @both=();
	my @folders=@_;
	my @all=();
	while (defined(my $current_folder = pop(@folders))) {
		if(!defined $current_folder) {
			croak ("ERROR:hentTre:katalog ikke definert. $current_folder");
		}
		elsif(-f $current_folder) {
			push(@all,$current_folder);
			next;
		}
		my $error_current_folder=$current_folder;
		$current_folder=~/$osfilter/;#/([\w\/\~Ã¦Ã¸Ã¥Ã¶Ã»ÃÃÃ .&\+\,\#\~\%\)\(\[\]\{\}\'\Â´\!+-\?]+)/;
		$current_folder=$1;
		chdir($current_folder) or croak("Kan ikke åpne $current_folder. Var $error_current_folder. $!");
		@both = glob("*");
		foreach my $item (@both) {
			# next if (-l $item);
			if (-d $item) { #Get all folders into another array - so that first the files will appear and then the folders.
				if ($item ne "lost+found") {
					push(@folders,$current_folder . '/' . $item);
				}
			} else { #If it is a file just put it into the final array.
				push(@all,$current_folder .'/' . $item);
			}
		} # foreach
	} # while
	return @all;
} # sub

sub kopier {
	my $filTilKopiering=$_[0];
	$filTilKopiering=~/$osfilter/;#/([\@\w\/\~Ã¦Ã¸Ã¥Ã¶Ã»ÃÃÃ .&\+\,\#\~\%\)\(\[\]\{\}\'\Â´\!+-]+)/;
	$filTilKopiering=$1;

#	print"DEBUG kopier ",$filTilKopiering,"\n";
	if (! defined($filTilKopiering)) {
		croak "ERROR:forsøker å kopiere fil uten navn. $!. Avslutter... \n";
	}
	my $fil=$filTilKopiering;
	my $fullDir="\/";
	my @dummyDir=split(/\//,$fil);
	pop(@dummyDir);
	$fullDir=join("\/",@dummyDir);
#			print "DEBUG:2 \$fullDir:",$fullDir,"\n";

	$fullDir=$BACKUPDISK . $fullDir;
	if (! -d $fullDir) {
		chdir("\/") or croak"chdir \/ \n";
		$fil=$filTilKopiering;
		@dummyDir=split(/\//,$fullDir);
		print"DEBUG 32434",,"  ",$fil,"###",join(",",@dummyDir),"\n" if $debug==1;
#		print "DEBUG 12 \$fil\:",$fil,"  dummydir\:",$dummyDir,"\n";
		foreach my $currentDir(@dummyDir) {

			print "DEBUG:23 \$currentDir \"",$currentDir,"\"\n" if $debug==1;
			if(!($currentDir eq ""||$currentDir eq "lost+found")) {#fjerner katalog for unix disker
#				system("/bin/pwd");
				if(! -d $currentDir){
					make_path($currentDir) or croak "ERROR: Fikk ikke laget katalogen: $currentDir. $!";
					print "INFO lager subdir: \/",$currentDir,"\n";
				}
				chdir($currentDir) or croak "ERROR: Fikk ikke chdir til katalogen: $currentDir. $!";
#				print"DEBUG chdir ",$currentDir,"\n";
			}
		}
	}
	my $maalFil=$BACKUPDISK . $filTilKopiering;
	if ($test>0) {
		print "-test:KOPIERER $fil\n";
	} else {
		print "INFO kopierer ",$maalFil,"\n";
		copy($filTilKopiering, $maalFil) or confess "ERROR: Fikk ikke kopiert fra \"$filTilKopiering\" til \"$maalFil\" . $!\n";
		print LOGFILE "INFO kopiert ",$maalFil,"\n";
	}
}

sub slett {
#	print "DEBUG slett innput: ",join(", ",@_),"\n";
	my $filTilSletting=$_[0];
	$filTilSletting=~/^$BACKUPDISK$osfilter/;#/(^$BACKUPDISK[\@\w\/\~Ã¦Ã¸Ã¥Ã¶Ã»ÃÃÃ .&\+\,\#\~\%\)\(\[\]\{\}\'\Â´\!+-]+)/;
	$filTilSletting=$1;
	if (! defined($filTilSletting)) {
		croak "ERROR:forsøker å slette fil uten navn \n";
	}
#	if($filTilSletting=~/^$BACKUPDISK\/[\w-]+\//) { #ungår å slette rot filer på backup drevet.
	my $fil=$filTilSletting;
	if ($test>0) { #simulert sletting
		print "-test:SLETTER $fil\n";
	}
	else {#vanlig sletting
		print"INFO FJERNER",$fil,"\n";

		unlink $fil if (-f $fil);
		print LOGFILE "INFO FJERNER",$fil,"\n";
		my @dummyDir=split(/\//,$fil);
		pop(@dummyDir);
		my $fullDir=join("\/",@dummyDir);
        if ( -d $fullDir ) {
            print"DEBUG \$fullDir",$fullDir,"\n";
            chdir($fullDir);
            my @isEmpty=glob("*");
            #print"DEBUG \$\#isEmpty",$#isEmpty,," ",join(";",@isEmpty),"\n";
            while($#isEmpty == -1) {
                $fil=pop(@dummyDir);
                $fullDir=join("\/",@dummyDir);
                chdir($fullDir);
                print"INFO FJERNER MAPPEN: ",$fil,"\n";
                rmdir($fil);
                print LOGFILE "INFO FJERNER MAPPEN: ",$fil,"\n";
                @isEmpty=glob("*");
                print"DEBUG2 \$\#isEmpty",$#isEmpty,," ",join(";",@isEmpty),"\n";
            }
        }
	}
}
sub getConfigBackupDirs {
@catalogsForBackup = ();
	open (FILE, $CONFIG) or croak "Får ikke åpnet $CONFIG \n";
	while (<FILE>) {
		chomp;
		if (/^\//) {
			if (! (-d $_ ||-f $_) ) {
			croak "ERROR: Katalogen\/filen $_ finnes ikke. Sjekk $CONFIG !\n";
			}
			push(@catalogsForBackup, $_);
		}
	}
	close (FILE);
}
sub removeProtectedFilesFrom_backupFiles { #@backupFiles
	for ( my $index = $#backupFiles; $index >= 0; --$index )
	{
		if ($backupFiles[$index] !~ m!\Q$BACKUPDISK\E/.*?/.*!) { # remove certain elements
			print "DEBUG.SLETTER-rotfiler:",$index,"\n" if $debug==1;
			splice @backupFiles, $index, 1
		}
		elsif ( ($backupFiles[$index] =~ m!$BACKUPDISK/lost\+found!)) { # remove certain elements
			print "DEBUG.SLETTER lost+found:",$index,"\n" if $debug==1;
			splice @backupFiles, $index, 1
		}
	}
}
####################################
#	MAIN
####################################
my $sjekk=0;
$test=0;
$debug=0;
$nocopy=0;

$PROJECT_HOME='/home/stein';
$PROJECT_HOME =~ /([\w.-\/]+)/;
$PROJECT_HOME=$1;
$FILLOG=$PROJECT_HOME . "/logs/FilBackupLog.txt";
$PROJECT_HOME=$PROJECT_HOME . "/Backup";
#LESER OG BEHANDLER INNPUT
if ($#ARGV == -1) {
	&usage;
}

# Leser parametere eks -email fil.sql fil2.sql  [-sjekk][-debug]
while ($_=shift(@ARGV)) {#,/^-/
	# last if /^--$/;
	if (/^-debug$/) {#setter på noen debug flagg
		$debug=1;
	}
	elsif (/^-sjekk$/) {#gjennomfører bare forprosesseringen
		$sjekk=1;
	}
	elsif (/^-nocopy$/) {#gjennomfører bare forprosesseringen
		$nocopy=1;
	}
	elsif (/^-test$/) {#skriver til log fil istedenfor å gjøre disk operasjoner som slett og kopier
		$test=1;
	}
	else {
		push(@backupDisks,$_);
	}
}
print "DEBUG1:",join(", ",@backupDisks),"\n" if $debug;
#sjekker om truecrypt filene har samme navn
foreach my $i (0..$#backupDisks) {
	foreach my $j ($i..$#backupDisks) {
		if ($i!=$j) {
			if ($backupDisks[$i] eq $backupDisks[$j]) {
				croak "ERROR: Spesifisert 2 like  truecrypt disker ",$backupDisks[$i],"\n";
			}
		}
	}
}
#LAGER truecryptdisk-liste med filer
#Av mounter eventuelle truecrypt disker
system("/usr/bin/truecrypt -t -d");
#looper gjennom truecryptdisk-listen. For å sjekke at alt er klart
my $i=0;
my $filBackupDisk="@";
my $hoppOver=0;
my @kopieringsListe = ();

foreach $filBackupDisk (@backupDisks) {
	$i++;
	$filBackupDisk=~/([\w\/ .-]+)/;
	$filBackupDisk=$1;
	croak "ERROR: disk ikke funnet eller avvist." if (! $filBackupDisk=~/[\w]+/);
	#mounter aktuell truecrypt disk/fil
	chdir($PROJECT_HOME);
	$BACKUPDISK="\/media\/truecrypt$i";

	my $out="/usr/bin/truecrypt -t  -k \"\" --protect-hidden=no $filBackupDisk $BACKUPDISK";
	print "DEBUGtruecryptout:",$out,"\n" if $debug==1;
	system($out);
	#
	# Sjekker at alt er klart
	if ( ! -d $BACKUPDISK ) {
		croak "ERROR: $BACKUPDISK må være mounted. Avslutter..\n";
	}

	$CONFIG="$BACKUPDISK/config-backup.txt";
	if ( ! -f $CONFIG ) {
		croak "ERROR: Konfig filen config-backup.txt må ligge på roten i drevet bassert på filen $filBackupDisk. Avslutter...\n";
	}
	#sjekker om alle pather i config finnes
	&getConfigBackupDirs(); #populerer @catalogsForBackup
	croak "ERROR: $CONFIG inneholder ikke kataloger det skal tas backup av. Ligger på drevet $filBackupDisk. Avslutter...\n" unless $#catalogsForBackup>=0;
	foreach my $backDir(@catalogsForBackup) {
		croak "ERROR:Katalogen\/filen $backDir finnes ikke. Feil med $CONFIG i truecrypt disken $filBackupDisk. Avslutter...\n" unless (-d $backDir || -f $backDir);

	}
	#sjekker om filer ligger utenfor backup stien slik at de kan bli slettet uten med vilje
	@backupFiles=&hentTre ($BACKUPDISK);
	&removeProtectedFilesFrom_backupFiles;
	my $sikkertikke=0;
	foreach my $BFdummy(@backupFiles) {
		my $ikke=1;
		foreach my $Cdummy(@catalogsForBackup) {
			if($BFdummy=~/$Cdummy/) {
				$ikke=0;
			}
		}
		if ($ikke==1) {
			print "På Backupdisk:", $filBackupDisk," vil fil: ",$BFdummy," bli slettet.\n";
			$sikkertikke=1;
		}
	}
	if ($sikkertikke==1) {
		print "Vil du fortsette? OK?(ja\/nei\/avbryt\/(h)opp over):";
		my $svar=<STDIN>;
		if(!($svar=~/^j/i||$svar=~/^y/i||$svar=~/^h/i)) {
			exit;
		}
		elsif ($svar=~/^h/i) {
			$hoppOver=1;
		}
	}
	if ($hoppOver==0) {
		push(@trueCryptDiskList,[ $filBackupDisk, $BACKUPDISK]);
	}
	$hoppOver=0;
	#Lager kopieringsliste
	if ($nocopy<1) {
		open (FILE, $CONFIG) or croak "Får ikke åpnet $CONFIG \n";
		while (<FILE>) {
			chomp;
			if (/^kopi\:\s*(.+)$/) {
				my $flagKatAlt=0;
				my @katAlt=split(/:/,$1);
				my $curKatAlt;
				while ($curKatAlt = shift(@katAlt)) {
					if (-d $curKatAlt ) {
						$flagKatAlt=1;
						last;
					}
				}
				if ($curKatAlt) {
					push(@kopieringsListe, [$filBackupDisk,$curKatAlt]);
				}
				else {
					croak "ERROR:$1 finnes ikke. Sjekk $CONFIG og om disk er mountet !\n";
				}
			}
		}
		close (FILE);
	}
}
#loop ferdig
if ($sjekk==1) {
	exit;
}
#oppdatering av backupfiler
print "\n	Starter selve oppdateringen av backupfilene\n";
open (LOGFILE,"> $FILLOG") or croak "Får ikke åpnet $FILLOG \n";
my @datetime=localtime(time);
printf LOGFILE "Start time:%d-%d-%d %d:%d\n",$datetime[5]+1900,$datetime[4]+1,@datetime[3,2,1];

#LOOP hovedloep. Oppdaterer backupfilene. Uten interasjon med bruker
foreach my $row (0..$#trueCryptDiskList) {
	$filBackupDisk=$trueCryptDiskList[$row][0];
	$BACKUPDISK=$trueCryptDiskList[$row][1];
	croak "ERROR:\$BACKUPDISK udefinert. Ved start av hoved loop. $filBackupDisk. Debug info\n" unless defined $BACKUPDISK;
    printf LOGFILE "\nBackup disk $filBackupDisk - $BACKUPDISK\n";
	# Leser konfig fil
	$CONFIG="$BACKUPDISK/config-backup.txt";
	print "DEBUG100:",$filBackupDisk,"\n" if ($debug==1);

	&getConfigBackupDirs(); #populerer @catalogsForBackup
	print "DEBUG paths:",join(", ",@catalogsForBackup),"\n" if ($debug==1);

	my @liveFiles=&hentTre (@catalogsForBackup);
	@backupFiles=&hentTre ($BACKUPDISK);
	&removeProtectedFilesFrom_backupFiles;
	#@backupFiles=grep(/$BACKUPDISK\//,@backupFiles);
	my %newFiles=();
	my @deletingFiles=();
	foreach my $dummy(@liveFiles) {
		$newFiles{ $dummy }=$dummy;
	}
	print "DEBUG LIVE TRE:\n",join("\n",@liveFiles),"\n" if ($debug==1);
#	print "\n\n";
	print "DEBUG BACKUP TRE:\n",join("\n",@backupFiles),"\n" if ($debug==1);

	print "\n\n\nDEBUG MAIN\n" if ($debug==1);
	print "DEBUG \@backupFiles: @backupFiles :\$BACKUPDISK==$BACKUPDISK\n" if ($debug==1);
	foreach my $backupFile (@backupFiles) {
		$backupFile=substr($backupFile,length($BACKUPDISK));
		print "DEBUG backupfile: ",$backupFile,"\n" if ($debug==1);;
		my $finnes=0;
		foreach my $liveFile (@liveFiles) {
		print "DEBUG filsammenligning: ",$backupFile,"==",$liveFile,"\n" if ($debug==1);;
			chomp($liveFile);
			if ( lc($backupFile) eq lc($liveFile) ) {#ikke case sensitiv
				print $backupFile,": finnes\n" if ($debug==1);
				$finnes=1;
				delete $newFiles{$liveFile};
				(my $Bdev,my $Bino,my $Bmode,my $Bnlink,my $Buid,my $Bgid,my $Brdev,my $Bsize,my $Batime,my $Bmtime,my $Bctime,my $Bblksize,my $Bblocks) = stat($BACKUPDISK . $backupFile);
				(my $Ldev,my $Lino,my $Lmode,my $Lnlink,my $Luid,my $Lgid,my $Lrdev,my $Lsize,my $Latime,my $Lmtime,my $Lctime,my $Lblksize,my $Lblocks) = stat($liveFile);
				#if -v da
				print join(", ",$Bdev,$Bino,$Bmode,$Bnlink,$Buid,$Bgid,$Brdev,$Bsize,$Batime,$Bmtime,$Bctime,$Bblksize,$Bblocks),"\n",join(", ",$Ldev,$Lino,$Lmode,$Lnlink,$Luid,$Lgid,$Lrdev,$Lsize,$Latime,$Lmtime,$Lctime,$Lblksize,$Lblocks),"\n"  if ($debug==1);
				if ($Bmtime >= $Lmtime && $liveFile=~/(mpg|mpeg|jpg|mp3|avi|jpeg|png|vob|gif|doc|ppt|info|txt|xml|xls|Thumbs.db|pl|odt|dll|css|html)$/i) {
					#for kjente filtyper så unvÃ¦res det å kopiere hvis ikke filen er nyere dato.
					#Dette pga truecrypt disker som ikke får ny dato ved endring.
					print LOGFILE $liveFile,": backup fil nyest. Ingen kopiering.\n";
				}
				else {
					print $liveFile,": behov for å oppdatere filen på backup.\n" if ($debug==1);
					croak "ERROR:\$BACKUPDISK udefinert\n" unless defined $BACKUPDISK;
					&kopier($liveFile);
				}
			}
			elsif($debug==1) {
				# print "$backupFile != $liveFile\n";
			}
		}
		if ( $finnes==0 )	{
		print "DEBUG ",$backupFile,"  ",substr($backupFile,length($BACKUPDISK)),"\n" if($debug==1);
			my $dummy=$backupFile;
			if ($dummy=~/\/[\w\~ .-]+\//) {
				print "DEBUGs:\$dummy:",$dummy,"\n" if($debug==1);
				push(@deletingFiles,$backupFile);
				my $backupFileDeleting=$BACKUPDISK . $backupFile;
				print LOGFILE $backupFileDeleting," slettes\n";
				&slett ($backupFileDeleting);
			}
		}
	}
	print "\nDEBUG NYE FILER:\n" if($debug==1);
	<STDIN> if($debug==1);

	foreach my $dummy (keys %newFiles) {
		if (defined ($dummy)) {
			# print LOGFILE $dummy," kopier\n";
			confess "ERROR: \$BACKUPDISK udefinert\n" unless defined $BACKUPDISK;
			&kopier ($dummy);
		}
	}
#LOOP hoved ferdig. truecrypt drev liste Ferdig
}
printf LOGFILE "End time:%d-%d-%d %d:%d\n",$datetime[5]+1900,$datetime[4]+1,@datetime[3,2,1];
close (LOGFILE);
#Av mounter eventuelle truecrypt disker
chdir($PROJECT_HOME);
#@Vent=split (/\n/,system("lsof\|grep \-e\"\/media\/\"");
#print "\@vent",join(", ",@vent);
system("/usr/bin/truecrypt -t -d");
if ($nocopy==1) {
	croak "Avbryter før kopieringen.\n";
}

#loop gjennom kopi liste
foreach $i(0..$#kopieringsListe) {
	#kopier disk-fil til destinasjon
	print "Starter kopiering av ",$kopieringsListe[$i][0]," til ",$kopieringsListe[$i][1],"\n";
	copy($kopieringsListe[$i][0],$kopieringsListe[$i][1]) or croak "ERROR: Fikk ikke kopiert fra \"$kopieringsListe[$i][0]\" til \"$kopieringsListe[$i][1]\" . $!\n";
#loopslutt
}
#skriv en linje om det gikk bra eller ikke.
print "Ferdig\!\n For å se hva som har skjedd med filene se \ncat $FILLOG\n";
