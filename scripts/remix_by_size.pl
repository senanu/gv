#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Cwd;
use JSON;

use version; our $VERSION = qv('1.0.1');

if (@ARGV == 0) { pod2usage()}; # print help if no argument given
my @infile;
my $snpfile;
my $cnvfile;

my $opts = GetOptions("help|h"        => sub{pod2usage({verbose=>3})},
                      ""               => sub{pod2usage(1)},
                      "infile|i=s"     => \@infile,
                      "snpfile|s=s"    => \$snpfile,
                      "cnvfile|c=s"    => \$cnvfile,
                                            # =s for strings, =i for ints 
                                            # = makes it required, : optional
    ) or pod2usage();

my $cnv;
my $snp;

foreach my $file (@infile) {
    open (my $in, "<", $file) or die "Couldn't open $file\n";
    local $/=undef;
    my $raw = <$in>;
    my $dat = JSON::from_json($raw);
    
    foreach my $variant (@$dat) {
        if ( $variant->{end} - $variant->{start} + 1 >= 1000) {
            push @$cnv, $variant;
        } else {
            push @$snp, $variant;
        }
    }
}

open (my $snpout, ">", $snpfile) or die;
open (my $cnvout, ">", $cnvfile) or die;

print $snpout JSON::to_json($snp, {pretty => 1, canonical => 1});
print $cnvout JSON::to_json($cnv, {pretty => 1, canonical => 1});



$DB::single=1;
print "";




__END__

=head1 NAME

remix_by_size.pl - 

=head1 SYNOPSIS

 remix_by_size.pl --infile infile
                 --outfile outfile

=head1 OPTIONS

=over

=item B<-h --help>

Print this message

=item B<-i --infile>

Input file

=item B<-o --outfile>

Output file

=item B<>

=back

=head1 DESCRIPTION



=head1 SEE ALSO

=head1 AUTHOR

Senanu Spring-Pearson Senanu.Pearson --at-- gmail.com

=cut
