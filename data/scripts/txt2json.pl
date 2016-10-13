#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Cwd;
use Columns;
use JSON;


use version; our $VERSION = qv('1.0.1');

if (@ARGV == 0) { pod2usage()}; # print help if no argument given
my $infile;
my $outfile;
my $filetype;
my $header;

my $opts = GetOptions("help|h"        => sub{pod2usage({verbose=>3})},
                      ""               => sub{pod2usage(1)},
                      "infile|i=s"     => \$infile,
                      "outfile|o=s"    => \$outfile,
                      "filetype|f=s"   => \$filetype,
                      "header|h"       => \$header,
                  ) or pod2usage();

my $col = new Columns($filetype);

open (my $in, "<", $infile) or die "Couldn't open $infile\n";

my $dat;
my $lineno = 0;
while ( my $line = <$in> ) {
    $lineno++;
    chomp $line;
    if ($header && $lineno == 1){
        next;
    }
    my @fields = split (/\|/, $line);
    my $line_dat;
    foreach my $key (keys %$col) {
        $line_dat->{$key} = $fields[$col->{$key}];
    }
    push @$dat, $line_dat;
}

my $json = to_json($dat, {pretty => 1, canonical=>1});
open (my $out, ">", $outfile) or die "Couldn't open $outfile\n";

print $out $json;


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
