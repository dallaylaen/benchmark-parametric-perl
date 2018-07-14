#!perl

use strict;
use warnings;
use Test::More;

use Benchmark::Parametric;

my $bm = Benchmark::Parametric->new( max_time => 0.1 );

my @trace;
my $stat = $bm->run( sub { push @trace, shift } );

cmp_ok $trace[-1], "<", $trace[-1]+1, "Last arg still subject to increment";
cmp_ok $trace[-1]*2, "==", $trace[-1]*2+1,
    "Twice the last arg loses precision if incremented";
note "last argument = $trace[-1], total count = ".scalar @trace;

is $stat->count, scalar @trace, "Count as expected";
note "slope around zero: ", $stat->slope;

done_testing;
