package Benchmark::Parametric::Comparison;

use 5.010;
use Moo;
our $VERSION = '0.01';

=head1 NAME

Benchmark::Parametric::Comparison - results of parametric benchmarking

=head1 SYNOPSIS

=head1 METHODS

=cut

use overload '""' => "to_string";
has results => is => 'ro', default => sub {{}};

=head2 new

No parameters available.

=head2 results

A hash of raw results (name => L<Benchmark::Parametric::Stat>).
This is for internal usage mostly.

=cut

=head2 add_result

    add_result( name => $stat_object )

Add a result to the comparison.
Must support ops_per_second method.
No checks are made so far.

=cut

sub add_result {
    my ($self, $name, $data) = @_;

    # TODO check args, forbid dupes
    $self->results->{$name} = $data;
};

=head2 get_result

    get_result( $name )

Fetch a previously recorded result.

=cut

sub get_result {
    my ($self, $name) = @_;

    return $self->results->{$name};
};

=head2 names

Returns all known result identifiers, sorted alphabetically.

=cut

sub names {
    my $self = shift;

    my @data = sort keys %{ $self->results };
    @data;
};

=head2 ops_per_second

Returns a hash reference containing all results and their corresponding
C<ops_per_second> counts.

=cut

sub ops_per_second {
    my $self = shift;

    return { map { $_ => $self->results->{$_}->ops_per_second } $self->names };
};

=head2 to_string

Produces a summary like that of L<Benchmark>.

=cut

sub to_string {
    my $self = shift;

    my $cross = _cross_table( $self->ops_per_second );

    my @head  = qw( name op/sec );
    push @head, map { $_->[0] } @$cross;

    my @table = (\@head, @$cross);

    return _tabulate( \@table );
};

# TODO find module!!!!
sub _tabulate {
    my $tab = shift;

    my @width;
    foreach my $line( @$tab ) {
        foreach (0 .. @$line-1) {
            $width[$_] and $width[$_] >= length $line->[$_]
                or $width[$_] = length $line->[$_];
        }
    };
    @width = map { "%${_}s" } @width;

    foreach my $line( @$tab ) {
        foreach (0 .. @$line-1) {
            $line->[$_] = sprintf $width[$_], $line->[$_];
        }
    };

    return join "\n", map { join " ", @$_ } @$tab, [];
};

sub _cross_table {
    my $in = shift;

    my @raw = map { [ $_ => $in->{$_} ] }
        sort { $in->{$a} <=> $in->{$b} } keys %$in;

    foreach my $line ( @raw ) {
        push @$line, map { _percent_diff($_->[1], $line->[1]) } @raw;
    };
    $_->[1] > 100 and $_->[1] = sprintf "%0.0f", $_->[1]
        for @raw;

    return \@raw;
};

sub _percent_diff {
    my ($old, $new) = @_;

    return "--" if $old == $new;

    my $diff = $new / $old;
    if ($diff < 1/1.6 || $diff > 1.6) {
        return sprintf "x%1.1f", $diff;
    } else {
        return sprintf "%1.0f%%", ($diff - 1) * 100;
    };
};

1;
