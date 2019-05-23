package SH::Code::Template;
use Mojo::Base -base;
use Mojo::File 'path';
use Clone 'clone';
use open ':encoding(UTF-8)';
use utf8;

=head1 NAME

SH::CodeTemplates - parent of the templates.

=head1 DESCRIPTION

Basis for templates. A template should generate a template for code file(script, module)
and a test file. And sometimes extra like config file example.

The template should make it easy to start coding.

=head1 ATTRIBUTES

=head2 dryrun

Do not make files but print instead.

=head2 force

Over write existing files. Nice when developing new templates.

=cut

has 'dryrun';
has 'force';


=head1 METHODS

=head2 name

Friendly name of the module. Used by the plugin parameter.
This must be replaced in child object.
=cut


sub name {
    my $self = shift;
    die "Missing name for module ". ref $self;
}

=head2 help_text

Text which is printet with the pluginshelp option.
This must be replaced in child object.

=cut

sub help_text {
    my $self = shift;
    die "Missing help_text for module ". ref $self;
}

=head2 generate

Called when script will generate files.
This must be replaced in child object.

=cut

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
    if (!$self->force && ! -d "$pa") {
        die "Path $pa must exists from current path. Bail out!";
    }
    my $fi = $pa->child($input->{filename});
    if (! $self->force && -e "$fi") {
        die "$fi exists! Bail out!";
    }
    if ($self->dryrun) {
        say $out;
    } else {
        $fi->spurt(Enode::encode('UTF-8',$out)); # spurt is hard with utf8
        # $fi->chmod(0755); does not work on Mojolicious 7.70
        chmod(0755, "$fi");
    }


}

=head2 required_variables

This metods should return a 2-parameter array of array. [['param','desc'],[p2,'d2']]
This must be set in child object.

=cut

sub required_variables {
    my $self = shift;
    die "Missing required_variables in ". ref $self;
}

=head2 optional_variables

This metods should return 2 paramater array of array [['param','desc'],[p2,'d2']]

=cut

sub optional_variables {
    return;
}

=head2 get_missing_param

Look for missing parameters. Ask user if found missing  required parameter.

=cut

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
