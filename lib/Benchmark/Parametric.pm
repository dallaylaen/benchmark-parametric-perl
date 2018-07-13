package Benchmark::Parametric;

use 5.006;

=head1 NAME

Benchmark::Parametric - Parametric benchmarking

=head1 DESCRIPTION



=head1 SYNOPSIS



    use Benchmark::Parametric;

    my $bm = Benchmark::Parametric->new( maxtime => 1);
    my $stat = $bm->run( \&codes );

    printf "Codes is as fast as %0.1f rps\n", $stat->rps;

=head1 METHODS

=cut

use Moo;
our $VERSION = '0.01';

use Time::HiRes qw(time);

use Benchmark::Parametric::Stat;

has setup    => is => 'lazy', builder => sub { sub { @_ }; };
has teardown => is => 'lazy', builder => sub { sub { 1 } };
has maxtime  => is => 'lazy', builder => sub { 1 };
has stoptime => is => 'lazy', builder => sub { 10 * $_[0]->maxtime };
has scale    => is => 'lazy', builder => sub { 1.3 };

=head2 new

    Benchmark::Parametric->new( %options )

%options may include:

=over

=item * setup - prepare environment for code under test.

=item * maxtime - time to execute code under test.

=back

=cut

=head2 run

    $bm->run( \&code )

C<code> must take 1 integer argument.

Execute C<code> multiple times with different argument values,
measure execution times, and record statistics.

Returns a L<Benchmark::Parametric::Stat> instance.

=cut

sub run {
    my ($self, $code) = @_;

    my $left = $self->maxtime;
    my $tstop = $self->stoptime;
    local $_ = 1;
    my $setup = $self->setup;
    my $teardown = $self->teardown;

    my $stat = Benchmark::Parametric::Stat->new;
    while ($left > 0) {
        $_ = int ( $_ * $self->scale + 1 );
        my $arg = $setup->( $_ );

        alarm $tstop if $tstop;
        my $t0 = time;
        my $ret = $code->($arg);
        my $time = time - $t0;
        alarm 0;

        $teardown->($ret); # or die?
        $stat->add_point($_, $time);
        $left -= $time;
    };

    return $stat;
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
