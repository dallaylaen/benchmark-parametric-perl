package Benchmark::Parametric;

use 5.010;
use Moo;
our $VERSION = '0.01';

=head1 NAME

Benchmark::Parametric - Measure and compare code speed.

=head1 DESCRIPTION

This module measures the performance of Perl code blocks.

It does so by passing an integer parameter (typically iteration count)
to the subroutine under test and examining the resulting execution times.

Such approach allows to time exactly the iterated snippet
as the surrounding code is cancelled out.

=head1 SYNOPSIS

Comparing code snippets or idioms, outputting a summary
similar to that of L<Benchmark>:

    use Benchmark::Parametric;

    my $bm = Benchmark::Parametric->new;
    my $result = $bm->compare(
        naive => sub { do_something() for 1 .. $_ },
        pp    => sub { My::Module::do_something for 1 .. $_ },
        xs    => sub { My::Module::XS::do_something for 1 .. $_ },
    );
    print $result;

Measuring time to process a single array element,
while making sure that processing actually happened:

    use Benchmark::Parametric;

    my $bm = Benchmark::Parametric->new(
        setup    => sub { [ 1 .. $_ ] },
        teardown => sub { $_[0] == $_ or die "Noop detected" },
    );

    # dies if sub doesn't return the expected value
    my $stat = $bm->run( sub { my $i; $i++ for @{ $_[0] }; $i } );
    print $stat->ops_per_second;

=head1 METHODS

=cut

use Time::HiRes qw(time);

use Benchmark::Parametric::Stat;
use Benchmark::Parametric::Comparison;

has setup     => is => 'rw', default => sub { sub { shift }; };
has teardown  => is => 'rw', default => sub { sub { 1 } };
has max_time  => is => 'rw', default => sub { 1 };
has stop_time => is => 'rw', default => sub { 10 * $_[0]->max_time };
has scale     => is => 'rw', default => sub { 1.3 };
has max_arg   => is => 'rw', default => sub { 4_000_000_000 };
has min_arg   => is => 'rw', default => sub { 1 };

=head2 new

    Benchmark::Parametric->new( %options )

%options may include:

=over

=item * setup - prepare environment for code under test.

The argument is a coderef that receives a positive integer argument.
If present, its scalar context return will be passed to code under test
instead of the counter.

This may be used to generate arrays of data, temporary files etc.
The time spent in this subroutine is not accounted for.

$_ is the iteration count during run of this sub.

=item * teardown - check that output is correct and destroy temporary objects.

Whatever was returned by code under test is given to this subroutine.

$_ is the iteration count during run of this sub.

=item * max_time - cumulative execution time.

=item * stop_time - if the code doesn't return in this time,
assume it is hanging and die.

Default is C<max_time> * 10.

=item * scale - multiply parameter by this value with each iteration.

Default is 1.3

Note that parameter is rounded to an integer and increased by at least 1.

=item * min_arg - minimal parameter value. Default is 1.

=item * max_arg - maximum parameter value. Default is 4 billion.

=back

=cut

=head2 run

    $bm->run( \&code )

Execute C<code> multiple times with different argument values,
measure execution times, and record statistics.

C<code> must take 1 argument as returned by C<setup> function,
or a positive integer if no setup was specified.

C<$_> is set to the iteration count during the execution of code.

Returns a L<Benchmark::Parametric::Stat> instance.

=cut

sub run {
    my ($self, $code) = @_;

    my $left     = $self->max_time;
    my $tstop    = $self->stop_time;
    my $setup    = $self->setup;
    my $teardown = $self->teardown;

    local $_     = $self->min_arg;
    my $stat     = Benchmark::Parametric::Stat->new;
    while ($left > 0) {
        my $arg = $setup->( $_ );

        alarm $tstop if $tstop;
        my $t0 = time;
        my $ret = $code->($arg);
        my $time = time - $t0;
        alarm 0;

        $teardown->($ret); # or die?
        $stat->add_point($_, $time);
        $left -= $time;

        $_ = int ( $_ * $self->scale + 1 );
        $_ > $self->max_arg and last;
    };

    return $stat;
};

=head2 compare

    compare( name1 => \&sub1, ... )

Compare several methods of doing the same thing.
The rules for subroutines are the same as in the run() method discussed above.

Output is a L<Benchmark::Parametric::Comparison> object that can be simply
printed out to get a table like that of C<Benchmark>.

=cut

sub compare {
    my ($self, %codes) = @_;

    my $cmp = Benchmark::Parametric::Comparison->new;
    foreach my $name( keys %codes ) {
        my $stat = $self->run( $codes{$name} );
        $cmp->add_result( $name => $stat );
    };

    return $cmp;
};

=head1 AUTHOR

Konstantin S. Uvarin, C<< <khedin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-benchmark-linear at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Benchmark-Parametric>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Benchmark::Parametric

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Benchmark-Parametric>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Benchmark-Parametric>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Benchmark-Parametric>

=item * Search CPAN

L<http://search.cpan.org/dist/Benchmark-Parametric/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Konstantin S. Uvarin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Benchmark::Parametric
