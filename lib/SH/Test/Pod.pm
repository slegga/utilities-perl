package SH::Test::Pod;
use Mojo::Base -strict;
use autodie;
use Test::Pod;
use Pod::Simple::Text;
# use Test::Pod::Coverage;
use YAML::Tiny;
use Pod::Simple::SimpleTree;
use FindBin;
use List::Util qw /first/;
use List::MoreUtils qw /any uniq/;
use Clone 'clone';
use File::Find;
use Pod::Simple::Search;
use Mojo::File qw/path/;
use Data::Dumper;
use Carp qw /carp/;
use Pod::Spell;
use Pod::Coverage;
use Pod::Simple;
use File::Basename;

use Term::ANSIColor;
use Test::Builder::Module;
our @ISA    = qw(Test::Builder::Module Exporter);
our @EXPORT = qw(check_modules_pod check_scripts_pod);

my $CLASS = __PACKAGE__;
my $ok=1;
my $DICT_FILE = '/usr/share/dict/words';

=head1 NAME

SH::Test::Pod - Check pod for error

This module will be under construction for a while

=head1 SYNOPSIS

  use Test::Simple;
  use SH::Test::Pod;

  check_modules_pod({
  headers_required => [ 'NAME', 'SYNOPSIS', 'DESCRIPTION'
  , ['FUNCTIONS','METHODS','CLASS METHODS','INSTANCE METHODS'], 'AUTHOR'],
  headers_order => 'force',
  synopsis_compile => 1,
  spell_check => 1,
  skip => [SH::Utils::SQLMVTable],
  });

  check_scripts_pod({
  headers_required=>[ 'NAME', 'DESCRIPTION', 'AUTHOR'],
  });
  qdone_testing;

=head1 DESCRIPTION

A module for testing pod. Setup required headings in the pod. And control if Synopsis compiles. Highly configurable.
You can make your own configuration, just make a file named .basic-test-pod.yml. This file must be a YAML file.

The test will merge the configuration if personal and the test configuration differ (to a more strict test configuration.)

=head2 configuration file

Filename ~/.basic-test-pod.yml

Example data:

 ---
 name: Slegga
 module_pod:
    headers_required:
        - NAME
        - SYNOPSIS
        - DESCRIPTION
        - (?:METHODS|FUNCTIONS|CLASS METHODS|INSTANCE METHODS)
        - AUTHOR
    headers_order_force: 1
    synopsis_compile: 1
    name_module_name: 1
    spell_check: 1
    pod_required: 1
 script_pod:
    headers_requiredi:
        - NAME
        - (SYNOPSIS|DESCRIPTION)
        - AUTHOR
    headers_order_force: 1
    spell_check: 1
    pod_required: 1

=head3 keys

=over 4

=item headers_required

=item headers_order_force

=item synopsis_compile

=item name_module_name

=item spell_check

=back

=head1 FUNCTIONS

=head2 check_modules_pod

Check if pod headers is ok.

=cut

sub check_modules_pod {
    my $repo_cfg = shift;
    my $ok;
    my $cfg = _get_config($repo_cfg);
    my $modules;
    $modules = _all_module_name_path_hash_ref($cfg);
    while (my ($modulename, $podfile) = each %$modules) {
        next if ! $podfile;
		if (!_is_cfg_active($cfg, 'module_pod', 'pod_required'))	{
		    my $parser = Pod::Simple->new;
		    $parser->complain_stderr(1);
			if(! $parser->parse_file($podfile)->content_seen ) {
				next;
			}
		}

        pod_file_ok( $podfile, "POD syntax: $podfile" );
        $cfg->{master} = undef;
        if ( _is_cfg_active($cfg, 'module_pod', 'headers_required')) {
            _nms_check_pod($cfg, $modulename, $podfile, "POD content: $podfile" );
        }
        # warn $cfg->{master};

        if ( _is_cfg_active($cfg, 'module_pod', 'spell_check')) {
            _nms_spell_check($cfg, $modulename, $podfile, "POD spelling for $podfile" );
        }
    }

    return _return_test('check_modules');

}

=head2 check_scripts_pod

Check script pod

=cut

sub check_scripts_pod {
    my $repo_cfg = shift;
    #my $ok;
    my $cfg = _get_config($repo_cfg);
    my $scripts;
    $scripts = _all_scriptpaths_array_ref($cfg);
    my $parser = Pod::Simple->new();
    $parser->complain_stderr(1);

    for my $scriptpath(@$scripts) {
        next if ! $scriptpath;
        next if $scriptpath =~ /\.(sh|ptkdb|sql)$/i;
		if (!_is_cfg_active($cfg, 'script_pod', 'pod_required'))	{
   		    my $parser = Pod::Simple->new;
   		    $parser->complain_stderr(1);
   			if(! $parser->parse_file($scriptpath)->content_seen ) {
   				next;
   			}
   		}
        pod_file_ok( $scriptpath, "POD syntax: $scriptpath" );
        $cfg->{master} = undef;
        next if ! _is_cfg_active($cfg, 'script_pod', 'headers_required', 'spell_check');
#        my $parser = Pod::Simple::Text->new;
        if ( _is_cfg_active($cfg, 'script_pod' ,'headers_required')) {
            _nms_check_pod($cfg, undef, $scriptpath, "POD content: $scriptpath" );
        }

        if ( _is_cfg_active($cfg, 'script_pod', 'spell_check')) {
            _nms_spell_check($cfg, undef, $scriptpath, "POD spelling for $scriptpath" );
        }
    }

    return _return_test('check_modules');

}


=head2 spellcheck

Check input scalar for English spelling errors.
 $_[0}: text to be checked as scalar
 $_[1]: additional legal words as array reference
Return a list of unknown words from the text.

Read from ~/.dictionary.txt for own words.

Read from project_home/.dictionary.txt

Read from /local/net/etc/.dictionary.txt

=cut


sub spellcheck {
    my $text = shift; #text to be spellchecked
    my $extrawords_ar = shift;#additional legal words as
    my @mywords= split(/\b/, $text);
    @mywords = sort {lc($a) cmp lc($b)} @mywords;
     @mywords = uniq @mywords;

    my @return=();

    my @ownwordlist=();
    if ($extrawords_ar) {
        @ownwordlist=@{$extrawords_ar};
    }
    my $pdfile = $ENV{HOME} . '/.dictionary.txt';
    if (-r $pdfile) {
        open my $pdfh,'<',$pdfile;
        my @tmp = <$pdfh>;
        push @ownwordlist, @tmp;
        close $pdfh;
        @ownwordlist = map {my $x = $_; chomp $x;$x} @ownwordlist;
        warn "Empty list " if ! @ownwordlist;
    }

    # project dict
    if (-r '.dictionary.txt') {
        open my $pdfh,'<','.dictionary.txt';
        my @tmp = <$pdfh>;
        push @ownwordlist, @tmp;
        close $pdfh;
        @ownwordlist = map {my $x = $_; chomp $x;$x} @ownwordlist;
        }

    # global dict
    if (-r '/local/net/etc/.dictionary.txt') {
        open my $pdfh,'<','/local/net/etc/.dictionary.txt';
        my @tmp = <$pdfh>;
        push @ownwordlist, @tmp;
        close $pdfh;
        @ownwordlist = map {my $x = $_; chomp $x;$x} @ownwordlist;
    }


    my @newwords=();
    for my $word(@mywords){
        next if $word !~ /\w/;
        next if $word =~ /\d/;
        next if $word =~/\_/;
        next if $word =~ /^\w\w$/;
        next if $word =~ /^\w$/;
        next if any {$_ eq $word || $_ eq lc($word) } @ownwordlist;

        push @newwords, $word;
    }
    #print join("\n",@newwords);
#    print join(" ",@mywords);
#    my %capmywords = map {(lc $_,$_)} @newwords;
#    @newwords = map{lc} @newwords;
    @newwords = sort {$a cmp $b} @newwords;
    @newwords = uniq @newwords;
    @newwords = grep {defined $_ && $_} @newwords;

    open my $fhr,'<', $DICT_FILE;
    my $word = shift @newwords;
    my $dword=<$fhr>;

    while (defined $dword && defined  $word) {

        if ($dword eq $word || $dword eq lc $word) {
            $word = shift @newwords;
            $dword = <$fhr>;
            chomp $dword if defined $dword;
        } elsif ( $dword lt $word) {
            if  ( $dword lt lc $word ) {
                $dword = <$fhr>;
                chomp $dword if defined $dword;
            }
        } elsif ( $dword gt $word) {
            if  ( $dword gt lc $word) {
                push @return, $word;
                $word = shift @newwords;
            } else {
                push @newwords,lc $word;
                @newwords = sort {$a cmp $b} @newwords;
                @newwords = uniq @newwords;
                $word = shift @newwords;
            }

        } else {
            die "$word dict:$dword ";
        }

        #die "No die $dword $word";
    }
    close $fhr;
    return @return;#@capmywords{@return};
}



# _get_config
# Return config tree. Root is repo and user.
# Calculate user config

sub _get_config {
    my $repo_config = shift;
    my $tmprepo = clone $repo_config;
    my $tmpuser = clone $repo_config;
    my $return = {repo => $tmprepo, user => $tmpuser};

    my $ownyml = "$ENV{HOME}/.basic-test-pod.yml";
    if (-f $ownyml) {
        open my $FH, '<', $ownyml or die "Failed to read $ownyml: $!$@";
        my $personal = YAML::Tiny::Load(
            do { local $/; <$FH> }
        );    # slurp content

        #merge content
        $return->{user}->{name} = $personal->{name} || die "You must define name in your $ownyml file.";
        die "You must define module_pod in your $ownyml file." if (! exists $personal->{module_pod});
        for my $realm(qw/module_pod script_pod/) {
            for my $key (keys %{ $personal->{$realm} }) {
                if (!exists $return->{user}->{$realm}->{$key}) {
                    $return->{user}->{$realm}->{$key} = $personal->{$realm}->{$key};
                }
                elsif (grep{$_ eq $key } qw/synopsis_compile name_module_name headers_order_force spell_check/ ) {
                    $return->{user}->{$realm}->{$key}||=$personal->{$realm}->{$key}; # if differ turn it on
                }
                elsif (ref $return->{user}->{$realm}->{$key} eq 'ARRAY' && ref $personal->{$realm}->{$key} eq 'ARRAY') {
                    # merge arrays and keep order
                    my %order;
                    my $i=0;
                    for my $key(@{$return->{user}->{$realm}->{$key}}) {
                        $order{$key}= $i;
                        $i=$i+1000;
                    }
                    $i=-1000;

                    for my $key (@{$personal->{$realm}->{$key}}) {
                        if (exists $order{$key}) {
                            $i = $order{$key} ;

                        } else {
                            $i++;
                            $order{$key} = $i;
                        }

                    }
                    my @array = sort { $order{$a} <=> $order{$b} } keys %order;
                    $return->{user}->{$realm}->{$key} = \@array;
                }
                else {
                    warn "In file $ownyml the item $key conflicts with config in $0. No default handeling is defined for $key. Keep module settings";
                }
            } #key
        } #realm
    } #own
#    warn Dumper $return;
    return $return;
}

# _is_cfg_active
# --------------
# $_[0] = $cfg;
# $_[1 ..] = 'KEY'
# return 1 if set to active else return false
# If missmatch module and user, turn it on.
# If more than one key this is a or

sub _is_cfg_active {
    my $cfg = shift;
    my $realm = shift;
    die "Missing keys" if ! @_;
    for my $key (@_) {
        return 1 if (exists $cfg->{repo}->{$key} && $cfg->{repo}->{$key});
        next if exists $cfg->{master} && defined $cfg->{master} && $cfg->{master} eq 'repo';
        return 1 if (exists $cfg->{user}->{$realm}->{$key} && $cfg->{user}->{$realm}->{$key});
    }
    return 0;
}

# _all_module_name_path_hash_ref
# TODO: Instead of using Pod::Simple::Search use Mojo::File. Right now only files with POD in it is returned.
# I want all files in lib/ that end with .pm

sub _all_module_name_path_hash_ref {
    my $cfg = shift;
    # warn  "$FindBin::Bin/../lib";
    my @paths;
    @paths = grep {$_ =~ /\.pm$/} path("$FindBin::Bin/../lib")->list_tree->grep (qr/^((?!\/auto\/).)*$/)->each;
    my $name2path={};
    for my $p(@paths) {
    	$name2path->{_path2name("$p")}= "$p";
    }
#    my $name2path = Pod::Simple::Search->new->inc(0)->survey("$FindBin::Bin/../lib");
    if (exists $cfg->{user}->{skip}) {
        for my $red(@{$cfg->{user}->{skip}}) {
            if ( first {$red eq $_} grep {$_} keys %$name2path) {
                delete $name2path->{$red};
            }
        }
    }
    return $name2path;
}

sub _path2name {
	my $path = shift;
	$path =~ s/.*\/lib\///;
	$path =~ s/\.pm$//;
	$path =~ s/\//::/g;
	return $path;

}

sub _all_scriptpaths_array_ref {
    my $cfg = shift;
    # warn  "$FindBin::Bin/../lib";
    my @paths;
    for my $basepath("$FindBin::Bin/../bin","$FindBin::Bin/../script") {
	    push @paths,path($basepath)->list_tree->grep(
	    sub{ defined $_[0]
#	    !exists $cfg->{skip}
#	    || !grep {$_[0] =~/$_$/} @{$cfg->{user}->{script_pod}->{skip}}
	    })->each;
    }
    my $return;
    for my $f(@paths) {
        next if exists $cfg->{repo}->{skip} && $cfg->{repo}->{skip} && grep {basename("$f") eq $_} @{ $cfg->{repo}->{skip} };
        push @$return,$f->to_string;
    }

    return $return;
}

sub _req_get_text {
	my $poditem = shift;
	if (ref $poditem eq 'ARRAY') {
		die "Not enough elements" . Dumper $poditem if $#$poditem<2;
		return _req_get_text($poditem->[2]);
	} elsif(ref $poditem) {
		warn Dumper $poditem;
		...;
	}
	return $poditem;
}

sub _nms_check_pod {
    my $in_cfg = shift;
    my $modulename = shift;
    my $podfile = shift;
    my $name = shift;
    if (! exists $in_cfg->{repo} ) {
 	   	_print_fail("Missing repo config file for test-pod.");
	   	_return_test($name);
	   	return;
    }

    # Pod::Simple->parse_file also work after __DATA__ line
    # So need to do this work around
    # my $content = path($podfile)->slurp;
    #my @linesall = split(/\n/, $content);
    #my @lines;
    #my $data_flag=0;;
    #for my $l(@linesall) {
#        if ($l eq '__DATA__') {
#            $data_flag=1;
#            next;
#        } elsif ($l eq '__END__') {
#            $data_flag=0;
#            next;
#        }
#        if (! $data_flag) {
#push @lines, $l;
#        }
#    }
#    push @lines,undef;
 #   my $pod_hr_raw = Pod::Simple::SimpleTree->new->parse_lines(@lines)->root;
    my $pod_hr_raw = Pod::Simple::SimpleTree->new->parse_file($podfile)->root;
    # remove fluff
    shift @$pod_hr_raw;
    shift @$pod_hr_raw;
	die if ! ref $in_cfg;
    # my $ok=1;

    my $pod_hr = {};
    my @act_order=();
    my $head1;
    for my $item (@$pod_hr_raw) {
        next if ref $item eq 'HASH';
        if (ref $item eq 'ARRAY') {
            if ($item->[0] eq 'head1') {
                $head1 = $item->[2];
                _print_fail("$podfile:Duplicate. Header exists $head1") if exists $pod_hr->{$head1};
                 push @act_order, $head1;
            }
            else {
                if (ref $item->[2]) {

#                    if (ref $item->[2]->[2]) {
#                        warn Dumper $item->[2]->[2];
#                        warn $pod_hr;
#                        die "Got $item->[2]->[2] expected string";
#                    }
                    $pod_hr->{$head1} .= _req_get_text($item->[2]);
                } elsif (!defined $head1) {
                    _print_fail("$podfile: First text in POD must be a =head1");

                } else {
                    $pod_hr->{$head1} .= $item->[2].' ';
                }
            }
        }
        else {
            die "Expected array got $item";
        }
    }
    my $personal_name;
    if (! exists $in_cfg->{user} || ! exists $in_cfg->{user}->{name}) {
   	   	$in_cfg->{master} = 'repo';
		$personal_name = qr/fdgsdfti4ø5jtgkfgjø45tjø43øktlø4l3/;
    } else {
  	    $personal_name = qr/$in_cfg->{user}->{name}/;
    }

    my $cfg;
    if ( (! exists $in_cfg->{master} || ! defined $in_cfg->{master})
        && exists $pod_hr->{'AUTHOR'} && $pod_hr->{'AUTHOR'} =~ /$personal_name/i ) {
        $in_cfg->{master} = 'user';
    } else {
        $in_cfg->{master} = 'repo';
    }
    # warn $in_cfg->{master};

    $cfg = $in_cfg->{$in_cfg->{master}};

    for my $req_head(@{$cfg->{headers_required}}) {
        if (! any {$_ =~/$req_head/ } keys %$pod_hr ) {
            _print_fail("Missing header $req_head in $podfile");
        }
    }

    if ($cfg->{headers_order_force}) {
        my @req_order = @{$cfg->{headers_required}};
        while ( my $req_head = shift @req_order ) {
            while (my $act_head = shift @act_order) {
                if (defined $req_head && defined $act_head && $act_head =~ /$req_head/ ) {
                    $req_head = shift @req_order;
                }
            }
            if ( $req_head ) {
                _print_fail("Header $req_head not in order. Required order: ". join (',',@{$cfg->{headers_required}}) );
                last;
            }
        }
    }

    return _return_test($name);
    # my $pod_hr = $pod_hr_raw;
}

# _nms_spell_check(($cfg, $modulename, $podfile, "POD spelling for $podfile" );

sub _nms_spell_check {
    my $in_cfg = shift;
    my $modulename = shift;
    my $podfile = shift;
    my $name = shift;
    my $parser = Pod::Simple::Text->new();     #sentence => 0, width => 1000);{width => 1000}
    my $pod;

    open my $in_fh, '<', $podfile;
    open my $out_fh, '>', \$pod or die "Can't open variable: $!";
    Pod::Spell->new->parse_from_filehandle($in_fh,$out_fh);
    close $out_fh;
    close $in_fh;
    # warn $in_cfg->{master};

    if (! $in_cfg->{master}) {
        $in_cfg->{master} = ($pod=~/$in_cfg->{name}/img)?'user':'repo';
    }
    return if ! _is_cfg_active($in_cfg,($modulename?'module_pod':'script_pod'),'spell_check'); # Do not spell check others modules if not wanted

    # Do not check for function names
    my $additional_words=[];
    if ($modulename) {
        my $pc = Pod::Coverage->new(package => $modulename);
        my @subs = $pc->covered;
        @$additional_words = grep{$_} map{split(/\s/, $_)} @subs;
        push @$additional_words, grep{$_} map {lc $_} split('\:\:',$modulename)
    }

    $pod =~ s/\'\w+\'//gm;
    $pod =~ s/\"\w+\"//gm;
    $pod =~ s/\{\w+\}//gm;
    $pod =~ s/\[\w+\]//gm;
    $pod =~ s/\<\w+\>//gm;
    $pod =~ s/\$\w+//gm;
    $pod =~ s/[\w\_\-]+\.p[lm]//gm;


    #my $ok = 1;
    my @unknown = spellcheck($pod, $additional_words);
    warn $pod if @unknown;
    _print_fail("'". join (', ',  @unknown) . "' are unknown words. Correct spelling or add to your ~/.dictionary.txt, project .dictionary.txt or global /local/net/etc/.dictionary.txt") if  @unknown;
    return _return_test($name);
};


sub _print_fail {
    my $text = shift;
    state $pre_text='';
    $ok = 0;
    return if $text eq $pre_text;
    $pre_text = $text;
    print STDERR "$text\n";
}

sub _return_test {
    my $text = shift;
    my $send_ok=$ok;
    $ok=1;# reset
    # local $Test::Builder::Level = $Test::Builder::Level + 2;
    $CLASS->builder->ok( $send_ok, $text );
}

=head1 SEE ALSO

For perl policy for POD documentation: L<https://perldoc.perl.org/perlpodstyle.html>

=head1 AUTHOR

Slegga

=cut

1;
