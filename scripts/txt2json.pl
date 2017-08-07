#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Cwd;
use Columns;
use JSON;


use version; our $VERSION = qv('1.0.1');

#if (@ARGV == 0) { pod2usage()}; # print help if no argument given
my @infiles;
my $outfile="temp";
my $filetype;
my $header;
my $delim = "\|";
my $opts = GetOptions("help|h"        => sub{pod2usage({verbose=>3})},
                      ""               => sub{pod2usage(1)},
                      "infile|i=s"     => \@infiles,
                      "outfile|o=s"    => \$outfile,
		      "delim|d=s"      => \$delim,
                  ) ;#or pod2usage();

my $dat;

foreach my $file (@infiles){
open (my $in, "<", $file) or die "Couldn't open $file\n";
my $lineno = 0;
my @headers;
LINE: while ( my $line = <$in> ) {
    $lineno++;
    chomp $line;
    if ($lineno == 1){
      @headers = split(quotemeta($delim), $line, -1);
      next LINE;
    }
    my @fields = split (quotemeta($delim), $line, -1);
    foreach my $fieldnum (0..scalar(@fields)-1){
      $fields[$fieldnum] =~ s/^\s*//;
      $fields[$fieldnum] =~ s/\s*$//;
    }
    my $line_dat;
    foreach my $header_num (0..scalar(@headers)-1){
        $line_dat->{$headers[$header_num]} = $fields[$header_num];
    }
    push @$dat, $line_dat;
    $DB::single=1;
    print q{};
  }
}

my $json = to_json($dat, {pretty => 1, canonical=>1});
open (my $out, ">", $outfile) or die "Couldn't open $outfile\n";

print $out $json;
$DB::single=1;
print q{};

__END__

=head1 NAME

txt2json.pl - 

=head1 SYNOPSIS

 txt2json.pl --infile infile
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
