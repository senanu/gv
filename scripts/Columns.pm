package Columns;

use strict; 
use warnings;

use Carp;

sub new{
    my $class = shift;
    my $filetype = shift;
    my $self;
    if ( $filetype eq 'common') {
        $self = {"Gene Symbol"                    => 0,
                 "PMID"                           => 1,
                 "Unique ID"                      => 2,
                 "Study Type"                     => 3,
                 "Mutation Type Details"          => 4,
                 "Allele Change"                  => 5,
                 "Residue Change"                 => 6,
                 "Chromosome"                     => 7,
                 "Sequence Position Start"        => 8,
                 "Sequence Position End"          => 9,
                 "Genome Build"                   => 10,
                 "SNP"                            => 11,
                 "Odds Ratio"                     => 12,
                 "Variant Evidence"               => 13,
                 "Variant Stats"                  => 14,
                 "Variant Function"               => 15,
                 "Population Origin"              => 16,
                 "Population Stage"               => 17,
                 "Variant-disorder association"   => 18,
                 "CG1"                            => 19,
                 "CG2"                            => 20,
                 "F3"                             => 21,
                 "ASD? (1=yes 0=no)"              => 22,
                 "If 0, what disorder"            => 23,
                 "chr_GRCh38"                     => 24,
                 "start_GRCh38"                   => 25,
                 "end_GRCh38"                     => 26,
                 "regions_GRCh38"                 => 27,
                 "bases_unmapped_GRCh38"          => 28,
                 "start_end_mapped_GRCh38"        => 29,
                 "inversions_GRCh38"              => 30,
                 "variant_type"                   => 31,
                 "AutDB_link"                     => 32,
                 "external_link"                  => 33,
		 "pubmed"                         => 34,
             };
    } elsif ($filetype eq 'rare') {
        $self = {"Gene Symbol"                    => 0,
                 "PMID"                           => 1,
                 "Unique ID"                      => 2,
                 "Mutation Type Details"          => 3,
                 "Inheritance Pattern"            => 4,
                 "Inheritance Association"        => 5,
                 "Family Type"                    => 6,
                 "Allele Change"                  => 7,
                 "Residue Change"                 => 8,
                 "Chromosome"                     => 9,
                 "Sequence Position Start"        => 10,
                 "Sequence Position End"          => 11,
                 "Genome Build"                   => 12,
                 "Variant size"                   => 13,
                 "Variant Evidence"               => 14,
                 "Variant Stat"                   => 15,
                 "Variant Function"               => 16,
                 "Variant-disorder association"   => 17,
                 "RG1"                            => 18,
                 "RG2"                            => 19,
                 "F3"                             => 20,
                 "ASD? (1=yes 0=no)"              => 21,
                 "ASD variant inclusion/exclusion"      => 22,
                 "If 0, what disorder"                  => 23,
                 "Biallelic LoF variant in ASD case(s)" => 24,
                 "RG5 (Biallelic LoF)"                  => 25,
                 "De novo LoF in simplex ASD case"      => 26,
                 "RG6 (De novo LoF)"              => 27,
                 "chr_GRCh38"                     => 28,
                 "start_GRCh38"                   => 29,
                 "end_GRCh38"                     => 30,
                 "regions_GRCh38"                 => 31,
                 "bases_unmapped_GRCh38"          => 32,
                 "start_end_mapped_GRCh38"        => 33,
                 "inversions_GRCh38"              => 34,
                 "variant_type"                   => 35,
                 "AutDB_link"                     => 36,
                 "external_link"                  => 37,
		 "pubmed"                         => 38,
             };
    } elsif ( $filetype eq 'cnv') {
        $self = {"Patient ID"                     => 0,
                 "PMID"                           => 1,
                 "Case/control"                   => 2,
                 "Patient age"                    => 3,
                 "Patient gender"                 => 4,
                 "Primary diagnosis"              => 5,
                 "Clinical profile"               => 6,
                 "Cognitive profile"              => 7,
                 "CNV locus"                      => 8,
                 "CNV start"                      => 9,
                 "CNV end"                        => 10,
                 "CNV size"                       => 11,
                 "Genome build"                   => 12,
                 "CNV type"                       => 13,
                 "CNV validation"                 => 14,
                 "CNV validation description"     => 15,
                 "Primary disorder inheritence"   => 16,
                 "CNV inheritance"                => 17,
                 "Family profile"                 => 18,
                 "CNV-disease segregation"        => 19,
                 "CNV gene content"               => 20,
                 "Altered gene expression"        => 21,
                 "chr_GRCh38"                     => 22,
                 "start_GRCh38"                   => 23,
                 "end_GRCh38"                     => 24,
                 "regions_GRCh38"                 => 25,
                 "bases_unmapped_GRCh38"          => 26,
                 "start_end_mapped_GRCh38"        => 27,
                 "inversions_GRCh38"              => 28,
                 "variant_type"                   => 29,
                 "AutDB_link"                     => 30,
                 "external_link"                  => 31,
		 "pubmed"                         => 32,
             };
    } else {
        croak "Unknown filetype in Columns.pm\n";
    }
    bless $self, $class;
    return $self;
}

    1;
__END__

=head1 NAME

Columns - module for keeping up with column headers from Excel files
as they pertain to text files without them.

=head1 SYNOPSIS

   use Columns;
   my $cols = new Columns('rare');
      ## 'rare', 'common', or 'cnv' are accepted
   $cols->{"Unique ID"}
      ## produces the column number of field "Unique ID"


=head1 DESCRIPTION

Provides the column numbers when you know the name of the column. This
helps keep several scripts all using the same notation without having
to change it in multiple places if the structure of the file changes.
Just change it within this document


=head2 EXPORT

None by default.

=head1 SEE ALSO

=head1 AUTHOR

senanu, E<lt>senanu.pearson@gmail.com<gt>

=head1 BUGS

None reported... yet.

=cut
