#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use SH::ScriptX;
use Mojo::Base 'SH::ScriptX';
use Mojo::Loader qw(data_section find_modules load_class);
use Mojo::File 'path';
use YAML::Tiny;
use utf8;
use open ':locale';

=head1 NAME

template.pl - generate code

=head1 DESCRIPTION

Generate script/modules/object and other code based on templates as a template. See Code::Template*

This script is ment to be ran at det root of the git repo/project.

Auto load modules in SH/CodeTemplate/Plugins.

Try template.pl --helptemplate for more info.

Planned templates:

=over 2

=item scriptx - generate script in bin catalog and a testfile

=item mojoobject - standard module. and a test file.

=item gitrepo - generate standard test files, catalog structures, info etc.

=back



=cut

option 'helptemplate!', 'Show help text for all templates.';
option 'template=s',     'Generate files based on given template';
option 'name=s',       'Filename with out extention.';
option 'dryrun!',      'Do no changes.';
option 'force!',       'Overwrite existing files. Nice when developing templates';
has config =>sub {
    my $cfg_file = path($ENV{HOME},'.template.pl.yml');
    if (-r "$cfg_file") {
        return YAML::Tiny->read( "$cfg_file" )->[0];
    } else {
        return {};
    }
};

#,{return_uncatched_arguments => 1});

 sub main {
    my $self = shift;
    my @e = $self->extra_options;

    if (@e) {
        while (@e) {
            my ($key, $value) =(shift(@e), shift(@e));
            if ($key =~ /^\-\-\w+$/) {
                $key =~ s/^\-\-//;
                $self->{$key} = $value;
            } else {
                die "Invalid key $key. Must start with --";
            }
        }
    }

    my $template_prefix = 'SH::Code::Template';
    if (exists $self->config->{template_prefix} && $self->config->{template_prefix}) {
        $template_prefix = $self->config->{template_prefix};
    }
    my @templates = find_modules $template_prefix;
    if (!@templates) {
        die "Can not find templates which start with $template_prefix";
    }
    # Find modules in a namespace
    if ($self->helptemplate) {
        say "\nThe following values with dobble underline for template is valid:";
        for my $module (@templates) {
            # Load them safely
            # Handle exceptions
            if (my $e = load_class $module) {
              die ref $e ? "Exception: $e" : "Not found $module! $e";
            }

            say '';
            my $o = $module->new(dryrun=>$self->dryrun, force=>$self->force);
            say $o->name;
            say '=' x length($o->name);
            say $o->help_text;
            if ($o->required_variables) {
                say "\nRequired variables:";
                say '-------------------';
                for my $r(@{ $o->required_variables}) {
                    printf "%-15s - %s\n",@$r;
                }
            }
            if ($o->optional_variables) {
                say "\nOptional variables:";
                say '-------------------';
                for my $r(@{ $o->optional_variables}) {
                    printf "%-15s - %s\n",@$r;
                }
            }
            # And extract files from the DATA section
            #say data_section($module, 'main');
            say '';
        }
    }
    elsif ($self->template ) {
        my $pl = $self->template;
        for my $module (@templates) {
            if (my $e = load_class $module) {
              die ref $e ? "Exception: $e" : "Not found $module! $e";
            }
        }
        if (my ($template) = grep {$pl eq $_->name} map {$_->new(dryrun=>$self->dryrun, force=>$self->force)} @templates) {
            $template->generate($self);
        } else {
            say STDERR "Only following template names are loaded" .join(', ',);
            die "Could not find any module with '$pl'";
        }
    }
    else {
        die "Do not know what to do. Please se --help for help."
    }
    #use Carp::Always;

}

__PACKAGE__->new(options_cfg=>{extra=>1})->main();
