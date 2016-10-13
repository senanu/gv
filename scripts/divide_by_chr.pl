#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Cwd;
use JSON;
use File::Spec;

use version; our $VERSION = qv('1.0.1');

if (@ARGV == 0) { pod2usage()}; # print help if no argument given
my $infile;
my $outprefix;

my $opts = GetOptions("help|h"        => sub{pod2usage({verbose=>3})},
                      ""               => sub{pod2usage(1)},
                      "infile|i=s"     => \$infile,
                      "outprefix|o=s"  => \$outprefix,
    ) or pod2usage();

## Read in the data
open (my $in, "<", $infile) or die "Couldn't open $infile\n";
local $/=undef;
my $raw = <$in>;
my $dat = JSON::from_json($raw);

## Parse the outprefix so that if it contains any directory structure,
## that directory gets created if it doesn't exist, and the filename
## is isolated such that it is used as a key in the hash in the next section
my ($vol, $dir, $file_prefix) = File::Spec->splitpath($outprefix);

## Rearrange the data in a hash that is organized by chromosome
## Actually, the key is the outprefix concatenated with the chr.json
## as in CNV_1.json when the outprefix is 'CNV_'
my $outdat;
foreach my $variant (@$dat) {
    my $name = $file_prefix . $variant->{chr};
    push @{$outdat->{$name}}, $variant;
  }

## Create the output directory if it doesn't exist
if(! -e $dir){
  mkdir $dir;
}

## Print to the proper files
foreach my $chr (keys %$outdat) {
    open (my $out, ">", File::Spec->catpath($vol, $dir, $chr . ".json")) or die;
    my $c_dat = JSON::to_json($outdat->{$chr}, {pretty=>1, canonical=>1});
    print $out $c_dat;
    close $out;
}



__END__

=head1 NAME

divide_by_chr.pl - Divide a json file into chromosome-specific files. the
output files are not currently sorted.

=head1 SYNOPSIS

 divide_by_chr.pl --infile infile
                  --outprefix outfile_prefix

=head1 OPTIONS

=over

=item B<-h --help>

Print this message

=item B<-i --infile>

 Input file. A json file with the structure:
  [
  {
    "chr": "1",
    "start": "1234",
    "end": "4444",
    etc. for any number of fields
  }
  ]

=item B<-o --outprefix>

The prefix for output files. If a path structure is given, then
the path will be created if necessary. Filenames will be within
the path structure and will be named "outprefix1.json", "outprefix2.json" etc.
according to the chromosome number.
Usually, this shoud be "../data/CNV_" or "../data/SNP_".

The output files will have the same structure as the input file.

=item B<>

=back

=head1 DESCRIPTION



=head1 SEE ALSO

=head1 AUTHOR

Senanu Spring-Pearson Senanu.Pearson --at-- gmail.com

=cut
