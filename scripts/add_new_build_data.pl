#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Cwd;
use Conversion;
use Columns;
use CleanUtils;

use version; our $VERSION = qv('1.0.1');
use Scalar::Util qw(reftype);
use open IN => ':utf8';     # help deal with non-breaking spaces in coords
use open OUT => ':locale';  # help deal with non-breaking spaces in coords



my $infile  ;
my $outfile ;
my $mapfile ;
my $filetype;
my $headers = 0;

my $opts = GetOptions("help|h"        => sub{pod2usage({verbose=>3})},
                      ""               => sub{pod2usage(1)},
                      "infile|i=s"     => \$infile,
                      "outfile|o=s"    => \$outfile,
                      "mapfile|m=s"    => \$mapfile,
                      "filetype|f=s"   => \$filetype,
                      "headers|h"      => \$headers, # print header line
    ) or pod2usage();


my $cols = new Columns($filetype);



## Read in entire json hash
my $convert = new Conversion($mapfile);

## Read variant line-by-line
## For each, match it to it's counterpart in the mapping hash
## and print it according to whether it is a CNV or not
open (my $in, "<", $infile) or die "Couldn't open $infile\n";
open (my $out, ">", $outfile);

## Print headers into output file, sorting by the value in the hash
if ( $headers) {
    my @headers = sort ({$cols->{$a} <=> $cols->{$b}} keys %$cols);
    print $out join("|", @headers) . "\n";
}

while ( my $line = <$in>) {
    chomp $line;
    ## get rid of extraneous spaces at the front and back of
    ## the data string, as well as around the pipes
    $line =~ s/^\s+|\s+$//g;      ## front and back of string
    $line =~ s/\s+\|/\|/g;        ## Before the pipe
    $line =~ s/\|\s+/\|/g;        ## After the pipe
    $line =~ s/\xA0//g;
    
    
    my @fields = split(/\|/, $line);
    ## Make the key depending on what type of file is input
    my $key;
    if ( $filetype eq 'common' || $filetype eq 'rare') {
        $key = $fields[$cols->{"Gene Symbol"}] . "|" .
            $fields[$cols->{"PMID"}] . "|" .
            $fields[$cols->{"Unique ID"}];        
    } elsif ( $filetype eq 'cnv') {
        $key = $fields[$cols->{"Patient ID"}] . "|" .
            $fields[$cols->{"CNV locus"}] . "|" .
            $fields[$cols->{"CNV size"}];
    } else {
        die "Unknown filetype $filetype\n";
    }

    if (defined $convert->getVariant($key)) {
    
        ## Set the start and end coordinates depending on what
        ## type of file is input
        my $start_original;
        my $end_original;
        my $variant_type;
	my $gene;
        my $AutDB_link;
        my $external_link = "";
        if ( $filetype eq 'common' || $filetype eq 'rare') {
            $start_original = $fields[$cols->{"Sequence Position Start"}];
            $end_original   = $fields[$cols->{"Sequence Position End"}];
            $variant_type   = $fields[$cols->{"Mutation Type Details"}];
	    $gene           = $fields[$cols->{"Gene Symbol"}];
	    if (defined $gene && $gene ne ''){
	      $AutDB_link     = "<a target='_blank' href=\'http://autism.mindspec.org/GeneDetail/$gene'>$gene</a>";
	    }
            my ($rs) = $fields[$cols->{"SNP"}] =~ /rs(\d+)/;
            if ( defined $rs && $rs ne '') {
                $external_link  = "<a target='_blank' href=\'http://www.ncbi.nlm.nih.gov/projects/SNP/snp_ref.cgi?rs=$rs\'>rs$rs</a>";
            }
        } elsif ( $filetype eq 'cnv') {
            $start_original = $fields[$cols->{"CNV start"}];
            $end_original   = $fields[$cols->{"CNV end"}];
            $variant_type   = $fields[$cols->{"CNV type"}];
            $AutDB_link     = "link to AutDB does not work for CNVs yet";
            $external_link  = "no external links for CNV-module variants";
	  }
	my $pubmed = $fields[$cols->{"PMID"}];
	$pubmed = "<a target='_blank' href=\'http://www.ncbi.nlm.nih.gov/pubmed/?term=$pubmed\'>$pubmed</a>";
        my $junk = [];
        $start_original = CleanUtils::fix_coord($start_original, $junk, $junk);
        $end_original   = CleanUtils::fix_coord($end_original, $junk, $junk); 
        ## make original endpoint same as start if it isn't given
        $end_original = $end_original eq '' || $end_original eq "Unknown" ?
            $start_original : $end_original;
        ## Drop in the start and end points from the data file into
        ## the map hash. If the start/end points are not mapped onto the
        ## newer genome build, then they won't appear in the json map,
        ## thus they need to be pulled in from the original data file.
        $convert->getVariant($key)->setOriginalStartAttempted($start_original);
        $convert->getVariant($key)->setOriginalEndAttempted($end_original);
        
        print $out $line  . "|" .
            $convert->getVariant($key)->getMappedChromosome() . "|".
            $convert->getVariant($key)->getStart()            . "|" .
            $convert->getVariant($key)->getEnd()              . "|" .
            $convert->getVariant($key)->getNumRegions()       . "|" .
            $convert->getVariant($key)->getBasesUnmapped()    . "|" .
            $convert->getVariant($key)->isStartEndMapped()    . "|" .
            $convert->getVariant($key)->getInversions()       . "|" .
            $variant_type                                     . "|" .
            $AutDB_link                                       . "|" .
            $external_link                                    . "|" .
	    $pubmed                                           . "\n";
    } else {
        print $out $line . "||||||||\n";
    }
}





$DB::single=1;
print q{};

__END__

=head1 NAME

add_new_build_data.pl - append data for a new build onto the pipe-delimited text file

=head1 SYNOPSIS

 add_new_build_data.pl -i infile.txt
                       -o outfile
                       -m mapfile.json
                       -f 'rare' # or 'common' or 'cnv'
                       -h

=head1 OPTIONS

=over

=item B<-h --help>

Print this message

=item B<-i --infile>

Input file from MindSpec database. This is pipe-delimited.

=item B<-o --outfile>

Output file (pipe-delimited)

=item B<-m --mapfile>

Json formatted file output from 'convert_to_grch38.pl'

=item B<-f --filetype>

File type output by Wayne's scripts. Possible values are 'rare', 'common',
and 'cnv'. To add additional values, check out the class Columns.pm

=item B<-h --headers>

Flag -- should a header line be printed in the output file?

=item B<>

=back

=head1 DESCRIPTION



=head1 SEE ALSO

=head1 AUTHOR

Senanu Spring-Pearson Senanu.Pearson --at-- gmail.com

=cut
