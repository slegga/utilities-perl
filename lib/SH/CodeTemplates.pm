package SH::CodeTemplates;
use Mojo::Base -base;
use Mojo::File 'path';
use Clone 'clone';

=head1 NAME

SH::CodeTemplates - parent of the templates.

=head1 DESCRIPTION

Basis for templates. A template should generate a template for code file(script, module)
and a test file. And sometimes extra like config file example.

The template should make it easy to start coding.

=head1 ATTRIBUTES

=head2 dryrun

Do not make files but print instead.

=cut

has 'dryrun';

=head1 METHODS

=cut

=head2 help_text

Text which is printet with the pluginshelp option.

=cut

sub name {
    my $self = shift;
    die "Missing name for module ". ref $self;
}

sub help_text {
    my $self = shift;
    die "Missing help_text for module ". ref $self;
}

sub generate {
    my $self = shift;
    die "Missing generate method for module ". ref $self;
}

=head2  generate_file

Generate wiched file based on input. Fi le must not exists else an error will be shown.

input is a hash ref with following keys.

=over 2

=item path - Relative and must exists.

=item filename - Filename

=item ts - template as string. Template protocoll Mojo::Template

=item parameters - all parameters for the template

=back

=cut

sub generate_file {
    my $self = shift;
    my $input = shift;
    die "Missing path" if ! exists $input->{path};
    die "Missing filename" if ! exists $input->{filename};
    my $mt = Mojo::Template->new(vars=>1);
    my $out = $mt->render( $input->{ts}, $input->{parameters} );
    my $pa =path( $input->{path} );
    if (! -d "$pa") {
        die "Path $pa must exists from current path. Bail out!";
    }
    my $fi = $pa->child($input->{filename});
    if (-e $fi) {
        die "$fi exists! Bail out!";
    }
    if ($self->dryrun) {
        say $out;
    } else {
        $fi->spurt($out);
    }


}

sub get_missing_param {
    my $self = shift;
    my $params = clone shift;
    for my $p (@{$self->required_variables}) {
        if (!exists $params->{$p->[0]}) {
            say $p->[0] .': '. $p->[1];
            print "$p->[0]: ";
            $params->{$p->[0]} = <STDIN>;
            chomp($params->{$p->[0]});
        }
    }
    return  $params;
}
1;
