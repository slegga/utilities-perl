package Test::Spell;
#does not work with æøå use open qw( :std :encoding(UTF-8) );
use Mojo::File 'path';
#use Text::Hunspell;
use Text::Aspell;
use Mojo::Base 'Test::Builder::Module',-base, -signatures;
use Test::More;
use Test::Builder::Module;
use Encode 'decode','encode';
use Mojo::File 'path';
use utf8;

has 'file';
has language=>'nb_NO'; # en_US
has speller => sub {
    my $aspell = Text::Aspell->new;
    $aspell->set_option('lang','no');
    $aspell->set_option('sug-mode','fast');
    return $aspell;
};
has mywords =>sub {
    my @ownwordlist;
    # project dict
    if (-r '.dictionary.txt') {
        open my $pdfh,'<','.dictionary.txt';
        my @tmp = <$pdfh>;
        push @ownwordlist, @tmp;
        close $pdfh;
        @ownwordlist = map {my $x = $_; chomp $x;decode('UTF-8',$x)} @ownwordlist;
    }
    return \@ownwordlist;
};
#sub { Text::Hunspell->new('','/usr/share/liblouis/tables/hyph_nb_NO.dic');
  #  "/usr/share/hunspell/en_US.aff",    # Hunspell affix file
#    "/usr/share/hunspell/".$_[0]->language.".aff", "/usr/share/hunspell/".$_[0]->language.".dic"     # Hunspell dictionary file
#)
#};

=head1 NAME

Test::Spell

=head1 SYNOPSIS

    use Test::More;
    use Test::Spell;
    my $t = Test::Spell->new(file => 't/data/my-text-file', language => 'norwegian');
    $t->test_text_spelling();
    done_testing;

=head1 DESCRIPTION

Try to make spellchecking like Test::Mojo;

=head2 ATTRIBUTES

=over 4

=item file - Filename for text file to spell check

=item language to check spelling against. -

=back

=head1 METHODS

=head2 test_text_spelling;

    $t->test_text_spelling;;

=cut

sub test_text_spelling($self,@params) {
    my $tb = __PACKAGE__->builder;
    my $ok = 1;
    my $reason = 'Spellcheck ok';
    if (! $self->file) {
        $ok = 0;
        $reason = 'Must set file attribute before test';
    }
    elsif (! -r $self->file) {
        $ok = 0;
        $reason = 'File: ' .$self->file. ' is missing';
    }
    my $string = decode('UTF-8',path($self->file)->slurp); #
    if (! $string) {
        $ok = 0;
        $reason = 'No data in file '. $self->file;
        return $tb->ok($ok,0,$reason);
    }
#    say $string;
    my @words = map {lc $_} grep {$_ !~ /^[A-ZÆØÅ][a-zæøå]*$/} split('[^\wæøåÆØÅ]+', $string);

    if (!@words) {
        return $tb->ok(1,'No words in file');
    }
    else {
   # warn join(',', grep {defined } @words);
        #my $words_utf8 = map{decode} @words;
        my %hw = map{$_ =>1 } @words;
        @words = keys %hw;
        my @wrongs;
        for my $w  ( @words ) {
            next if ! $w;
            next if $w =~/^\d+$/;
            next if (grep {$w eq $_} map{lc $_} @{ $self->mywords });
            if (! $self->speller->check($w)) {
                push @wrongs, $w;
            }
        }
        #push (@wrongs,$_) while ($self->speller->next_word);
        if (! @wrongs) {
            return $tb->ok($ok,$reason);
        }
        return $tb->ok(0, $self->file .' Gale ord: '. join(', ',map{$_} @wrongs));
    }
}

1;