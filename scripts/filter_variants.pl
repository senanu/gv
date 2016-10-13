#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Cwd;
use Columns;

use version; our $VERSION = qv('1.0.1');

if (@ARGV == 0) { pod2usage()}; # print help if no argument given
my $infile;
my $outfile;
my $header; # does the input file have a header?
my $filetype;
my $dirtyfile;

my $opts = GetOptions("help|h"        => sub{pod2usage({verbose=>3})},
                      ""               => sub{pod2usage(1)},
                      "infile|i=s"     => \$infile,
                      "outfile|o=s"    => \$outfile,
                      "header|h"       => \$header,
                      "filetype|f=s"   => \$filetype,
                      "dirtyfile|d=s"  => \$dirtyfile,
                  ) or pod2usage();

my $cols = new Columns($filetype);

open (my $in, "<", $infile) or die "Couldn't open $infile\n";
open (my $out, ">", $outfile) or die "Couldn't open $outfile\n";
open (my $dirty, ">", $dirtyfile) or die "Couldn't open $dirtyfile\n";

my $lineno = 0;
while ( my $line = <$in>) {
    $lineno++;
    if ( $header && $lineno == 1) {
        print $out $line;
        print $dirty $line;
        next;
    }
    # The fields added in the conversion are standard, even though they
    # may have a different location in the file
    my @fields = split(/\|/, $line);
    my $chr              = $fields[$cols->{chr_GRCh38}];
    my $regions          = $fields[$cols->{regions_GRCh38}];
    my $bases_unmapped   = $fields[$cols->{bases_unmapped_GRCh38}];
    my $start_end_mapped = $fields[$cols->{start_end_mapped_GRCh38}];
    my $inversions       = $fields[$cols->{inversions_GRCh38}];
    my $start;
    if ($filetype eq 'common' || $filetype eq 'rare') {
        $start = $fields[$cols->{"Sequence Position Start"}];
    } elsif ( $filetype eq 'cnv') {
        $start = $fields[$cols->{"CNV start"}];
    }
#    print $chr . "\t";
#    print "$regions\t";
#    print "$bases_unmapped\t";
#    print "$start_end_mapped\t";
#    print "$inversions\n";
    
    ## The following are the criteria for including in the output
    ## Also excludes 
    if ($chr ne 'multiple' &&
            $regions == 1 &&
            $bases_unmapped == 0 &&
            $start_end_mapped =~ /both/i &&
            $inversions == 0
        ) {
        if ( $start =~ /\[(\d+)\];\[(\d+)\]/ &&
                 $1 != $2 ) {
            # this includes the cases where there is a genotype given
            # as [1234];[1234] and listed as "Homozygotes show ..."
            # but does not include anything more complex like compound hets.
            print $dirty $line;
        } else {
            print $out $line;
        }
    } else {
        print $dirty $line
    }
}

close $out;
close $dirty;



    

__END__

=head1 NAME

filter_variants.pl - 

=head1 SYNOPSIS

 filter_variants.pl --infile infile
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
