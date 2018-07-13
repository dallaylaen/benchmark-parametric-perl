#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Carp;

use Benchmark::Parametric;

$SIG{ALRM} = sub {
    confess "The code hang for unknown reason";
};

my $bm = Benchmark::Parametric->new(
    maxtime => 0.001,
);

alarm 60;

my @trace;
my $sum; # unused, just make sure noop isn't optimized out
my $st = $bm->run( sub { push @trace, $_; $sum+=sqrt($_*$_) for 1 .. $_ } );

isa_ok $st, 'Benchmark::Parametric::Stat', "Result of run";
ok !(grep { !/^[1-9][0-9]*$/ } @trace), "All parameters are positive integers"
    or diag explain \@trace;


is $st->count, scalar @trace, "Exact number of data points recorded";
cmp_ok $st->slope, ">", 0, "Slope is positive for our noop";

done_testing;

