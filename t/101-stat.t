#!perl

use strict;
use warnings;
use Test::More;

use Benchmark::Parametric::Stat;

my $st = Benchmark::Parametric::Stat->new;

$st->add_point( $_, 0.5 + $_ * 0.125 ) for 0..4;

is $st->count, 5, "5 points";
is $st->constant, 0.5, "constant inferred correctly";
is $st->slope, 0.125, "slope inferred correctly";

is $st->ops_per_second, 8, "RPS in the ballpark";

done_testing;
