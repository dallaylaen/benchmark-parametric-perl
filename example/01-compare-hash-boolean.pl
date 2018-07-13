#!/usr/bin/env perl

# Compare different ways of converting hash to boolean

use strict;
use warnings;
use Benchmark::Parametric;

my $bm = Benchmark::Parametric->new (
    teardown => sub { shift == $_ or die "Not ++ed enough"; },
);

my %hash = ( 1 .. 20_000 );

print $bm->compare (
    noop   => sub { my $i; %hash             and $i++ for 1 .. $_; $i },
    keys   => sub { my $i; scalar keys %hash and $i++ for 1 .. $_; $i },
    exclam => sub { my $i; !!%hash           and $i++ for 1 .. $_; $i },
    scalar => sub { my $i; scalar %hash      and $i++ for 1 .. $_; $i },
);



