#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
my $backupdisk = '/tmp/backupdisk1';
print "Hello world\n";
if ($ARGV[0] eq 'mount') {
  mkdir($backupdisk);
  open my $fh,'>',$backupdisk."/config-backup.txt";
  print $fh "$FindBin::Bin".'/../fromdir'."\n";
  close $fh;
} elsif($ARGV[0] eq 'dismount') {
  unlink($backupdisk);
} else {
  die "Unknown option ".$ARGV[0];
}
