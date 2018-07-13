#!perl

use strict;
use warnings;
use Test::More;

use Benchmark::Parametric;

my $bm = Benchmark::Parametric->new( max_time => 0.001 );

my $result = $bm->compare(
    map  => sub { map  { $_ % 7 ? () : $_ } 1 .. $_ },
    grep => sub { grep { !($_ % 7) } 1 .. $_ },
);

isa_ok $result, 'Benchmark::Parametric::Comparison', "Result";

is_deeply [$result->names], ["grep", "map"], "Names preserved";

note $result->to_string;
my ($head, @lines) = split /\n/, $result->to_string;

is scalar @lines, 2, "2 lines in summary";

my ($first)  = $lines[0] =~ /([a-z]+)/;
my ($second) = $lines[1] =~ /([a-z]+)/;

is_deeply [sort ($first, $second)], ["grep", "map"], "Names preserved in summary";

# note: we assume that summary is sorted by ascending speed,
# so it should looks like
# foo nnn -- -\d
# bar nnn +\d --
like $head, qr{ *name +op/sec +$first +$second}, "Summary head as expected";
like $lines[0], qr/$first +[0-9]+ +-- +-[0-9]+[%x]/, "First line as expected";
like $lines[1], qr/$second +[0-9]+ +\+?[0-9]+[%x] +--/, "Second line as expected";


done_testing;
