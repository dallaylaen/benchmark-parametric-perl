package Benchmark::Parametric::Stat;

use 5.010;
use Moo;
our $VERSION = '0.01';

=head1 NAME

Benchmark::Parametric::Stat - Result of a parametric benchmark

=cut

has _data => is => 'ro', default => sub { [] };

=head2 new

=cut

=head3 add_point

    add_point( $arg, $time )

Add a point to the dataset.

=cut

sub add_point {
    my ($self, $x, $y) = @_;

    delete $self->{cache};
    push @{ $self->_data }, [ $x, $y ];
    $self;
};

sub _memoize ($$) { ## no critic
    my ($method, $code) = @_;

    my $sub = sub {
        my $self = shift;
        return $self->{cache}{$method} //= $code->($self);
    };

    no strict 'refs'; ## no critic
    *$method = $sub;
};

=head2 GETTERS

These functions will return inferred data parameters.
They are cached and only calculated once, unless new data was added.

=head3 count

Number of data points.

=cut

_memoize count => sub {
    my $self = shift;
    scalar @{ $self->_data };
};

=head3 slope

Time growth per argument. Linear approximation is used.

=cut

_memoize slope => sub {
    $_[0]->least_square->[1];
};

=head3 constant

Time spent in the code independent of parameter.

A negative value may imply that the dependency is non-linear.
A small negative value may just be a measurement error.

=cut

_memoize constant => sub {
    $_[0]->least_square->[0];
};

=head3 ops_per_second

Requests Per Seconds - the value one is going to boast about.

Currently this is just inverted slope, this MAY change in the future.

=cut

_memoize ops_per_second => sub {
    my $time = $_[0]->slope;
    $time ? 1/$time : 9**9**9;
};

=head3 least_square

Infer linear coefficient from data at hand.

This is called implicitly by constant() and slope() above.

Returns an arrayref, spec may change in the future.

=cut

_memoize least_square => sub {
    my $self = shift;

    my( $n, $x, $y, $x2, $xy);
    foreach (@{ $self->_data }) {
        $x  += $_->[0];
        $y  += $_->[1];
        $x2 += $_->[0]*$_->[0];
        $xy += $_->[0]*$_->[1];
        $n  ++;
    };

    # y =~ $const*x + $slope;
    my $slope = ($xy - $x*$y/$n) / ($x2 - $x*$x/$n);
    $slope = 0 if $slope < 0;
    my $const = ($y - $slope*$x) / $n;
    # TODO also calculate deviation & probability it's not linear

    [ $const, $slope ];
};

1;
