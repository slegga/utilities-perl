use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../utillities-perl/lib";
use SH::Test::Pod;

check_modules_pod({
# headers_required=>[ 'NAME', 'SYNOPSIS', 'DESCRIPTION', '(?:METHODS|FUNCTIONS)', 'AUTHOR'],
headers_required=>['NAME'],
headers_order_force=>0,     # force the order of headers if set
synopsis_compile=>0,        # compile synopsis and look for errors if set
#skip=>['SH::Utils'],
name => 'petra',
});

check_scripts_pod({
    headers_required=>[ 'NAME'],
    headers_order_force=>0,     # force the order of headers if set
});

done_testing;
