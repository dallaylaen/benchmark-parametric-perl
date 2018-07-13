#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Benchmark::Parametric' ) || print "Bail out!\n";
}

diag( "Testing Benchmark::Parametric $Benchmark::Parametric::VERSION, Perl $], $^X" );
