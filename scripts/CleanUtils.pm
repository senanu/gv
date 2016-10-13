package CleanUtils;

use strict; 
use warnings;
use List::Util qw(max);

use Carp;

sub fix_coord{
    ## Some of the coordinates are free-form strings
    ## To standardize them, we look for the largest number within the string
    ## and return it as the coordinate. This may not always be the truth.
    my $raw = shift @_;
    my $id  = shift @_;
    my $errors = shift @_;
    my @numeric = $raw =~ /(\d+)/g;
    if (scalar(@numeric) > 1) {
        push @$errors, "$id:\tWarning coordinates may not have parsed properly";
    } elsif (scalar(@numeric) == 0) {
        return "Unknown";
    }
    my $coord = max(@numeric);
    return $coord;
}

1;
__END__

=head1 NAME

CleanUtils - common functions for doing liftover

=head1 SYNOPSIS

   use CleanUtils;

   CleanUtils::fix_coord($a, $b, $c);

=head1 DESCRIPTION

=head2 EXPORT

None by default.

=head1 SEE ALSO

=head1 AUTHOR

Senanu Spring-Pearson

=head1 COPYRIGHT AND LICENSE

=head1 BUGS

=cut
