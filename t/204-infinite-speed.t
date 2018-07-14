#!perl

use strict;
use warnings;
use Test::More;

use Benchmark::Parametric;

my $bm = Benchmark::Parametric->new( max_time => 0.1 );

my @trace;
my $stat = $bm->run( sub { push @trace, shift } );

cmp_ok $trace[-1], "<", $trace[-1]+1, "Last arg still subject to increment";
cmp_ok $trace[-1], "<=", $bm->max_arg, "max_arg honored";
cmp_ok $trace[-1]*2, ">", $bm->max_arg, "max_arg approached as close as possible";
note "last argument = $trace[-1], total count = ".scalar @trace;

is $stat->count, scalar @trace, "Count as expected";
note "slope around zero: ", $stat->slope;

done_testing;
