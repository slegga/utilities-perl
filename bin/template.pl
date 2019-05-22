#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use SH::ScriptX;
use Mojo::Base 'SH::ScriptX';
use Mojo::Loader qw(data_section find_modules load_class);
use utf8;
use open ':locale';

=head1 NAME

template.pl - generate code

=head1 DESCRIPTION

Generate script/modules/object and other code based om plugins and templates

This script is ment to be ran at det root of the git repo/project.

Auto load modules in SH/CodeTemplate/Plugins.

Try template.pl --pluginshelp for more info.

Planned plugins:

=over 2

=item scriptx - generate script in bin catalog and a testfile

=item mojoobject - standard module. and a test file.

=item gitrepo - generate standard test files, catalog structures, info etc.

=back



=cut

option 'helpplugins!', 'Show help text for all templates.';
option 'plugin=s',     'Generate files based on given template';
option 'name=s',       'Filename with out extention.';
option 'dryrun!',      'Do no changes.';
option 'force!',       'Overwrite existing files. Nice when developing templates';

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
    # Find modules in a namespace
    if ($self->helpplugins) {
        say 'The following value for plugin is valid:';
        for my $module (find_modules 'SH::CodeTemplates') {
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
            # And extract files from the DATA section
            #say data_section($module, 'main');
            say '';
        }
    }
    elsif ($self->plugin ) {
        my $pl = $self->plugin;
        my @allplugins = find_modules 'SH::CodeTemplates';
        for my $module (@allplugins) {
            if (my $e = load_class $module) {
              die ref $e ? "Exception: $e" : "Not found $module! $e";
            }
        }
        if (my ($plugin) = grep {$pl eq $_->name} map {$_->new(dryrun=>$self->dryrun, force=>$self->force)} @allplugins) {
            $plugin->generate($self);
        } else {
            say STDERR "Only following plugin names are loaded" .join(', ',);
            die "Could not find any module with '$pl'";
        }
    }
    else {
        die "Do not know what to do. Please se --help for help."
    }
    #use Carp::Always;

}

__PACKAGE__->new(options_cfg=>{extra=>1})->main();
