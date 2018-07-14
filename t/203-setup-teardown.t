#!perl

use strict;
use warnings;
use Test::More;

use Benchmark::Parametric;

my @trace;

my $bm = Benchmark::Parametric->new(
    max_time => 0.001,
);

$bm->run( sub { push @trace, [$_, @_] } );

my @wrong = grep { @$_ != 2 or $_->[0] != $_->[1] } @trace;

is scalar @wrong, 0, "No unexpected records"
    or diag explain @wrong;

done_testing;
