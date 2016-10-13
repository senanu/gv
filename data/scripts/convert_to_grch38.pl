#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Cwd;
use JSON;

use HTTP::Tiny;
use Try::Tiny;
use LWP::Parallel::UserAgent;
use LWP::UserAgent::Determined;
use HTTP::Request;
use List::Util qw(max);


use Data::Dumper;

use version; our $VERSION = qv('1.0.1');

#if (@ARGV == 0) { pod2usage()}; # print help if no argument given
my $infile = '../data/HG_Sequence_Var_Common_Data.txt'; 
my $outfile = "./out.json";
my $errorfile = "./out.errors";
my $filetype = 'common';
my $target_assembly = "GRCh38";

my $opts = GetOptions("help|h"              => sub{pod2usage({verbose => 3})},
                      ""                    => sub{pod2usage(1)},
                      "infile|i=s"          => \$infile,
                      "outfile|o=s"         => \$outfile,
                      "filetype|f=s"        => \$filetype,
                      "errorfile|e=s"       => \$errorfile,
                      "target_assembly|t=s" => \$target_assembly,
    ) or pod2usage();

## Use the standard MindSpec file types:
$filetype = lc($filetype); #change to lowercase for standardization

my $col_names;

if ( $filetype eq 'cnv') { # use the CNV module filetype
    $col_names = { "build"      => 12,
                   "locus"      => 8,
                   "start"      => 9,
                   "end"        => 10,
                   "patient_id" => 0,
                   "PMID"       => 1,
                   "CNV_size"   => 11,
               };
} elsif ( $filetype eq 'common') {
    $col_names = {"build"       => 10,
                  'Gene Symbol' => 0,
                  'PMID'        => 1,
                  'Unique ID'   => 2,
                  'Chromosome'  => 7,
                  'Sequence Position Start' => 8,
                  'Sequence Position End'   => 9,
              };
} elsif ( $filetype eq 'rare') {
    $col_names = {"build"       => 12,
                  'Gene Symbol' => 0,
                  'PMID'        => 1,
                  'Unique ID'   => 2,
                  'Chromosome'  => 9,
                  'Sequence Position Start' => 10,
                  'Sequence Position End'   => 11,
              };
}

    
#        0  => "Patient ID",
#                  1  => "PMID",
#                  2  => "Case/control",
#                  3  => "Patient age",
#                  4  => "Patient gender",
#                  5  => "Primary diagnosis",
#                  6  => "Clinical profile",
#                  7  => "Cognitive profile",
#                  8  => "CNV locus",
#                  9  => "CNV start",
#                  10 => "CNV end",
#                  11 => "CNV size",
#                  12 => "Genome build",
#                  13 => "CNV type",
#                  14 => "CNV validation",
#                  15 => "CNV validation description",
#                  16 => "Primary disorder inheritence",
#                  17 => "CNV inheritance",
#                  18 => "Family profile",
#                  19 => "CNV-disease segregation",
#                  20 => "CNV gene content",
#                  21 => "Altered gene expression",
#              };

my $server = 'http://rest.ensembl.org';

# read the file
open (my $in, "<", $infile) or die "Couldn't open $infile\n";
my $line_number = 0;
my @errors;

my $rest_calls;
my ($build, $chr, $start, $end, $id);
my $id_2_calls;
my $calls_hash;
my $data;

while ( my $line = <$in> ){
    $line_number++;
    chomp $line;
    my @fields = split(/\|/, $line);
    ##########################################################################
    ## Get the fields necessary for the REST call.                          ##
    ##########################################################################
    ## IDs are constructed as concatenation of several fields, depending
    ##   on whether it is from the CNV file or the Human Gene Module
    ## In the CNV file, Chromosome must be parsed from the locus
    ## End coordinates may not be given, in which case they are the
    ##   same as the start coordinates
    ## Build is a messy field, particularly for the CNV file. So, we
    ##   look up a standardized name for the myriad names in the database
    ## Coordinates are sometimes tricky because they are given in free-form
    ##   strings. We parse out the string with the highest value and use that,
    ##   although it may not always be completely accurate. This is mostly
    ##   a problem in the CNV module. 
    if ($filetype eq 'cnv') {
        my $patient_id = $fields[$col_names->{patient_id}];
        my $PMID  = $fields[$col_names->{PMID}];
        my $CNV_size   = $fields[$col_names->{CNV_size}];
        $build = fix_build($fields[$col_names->{build}], $id, \@errors);
        my $locus = $fields[$col_names->{locus}];
        ($chr) = $locus =~ /([0-9XY]+)[pq]/;
        $id    = $patient_id . "|" . $locus . "|" . $CNV_size;
        $start = fix_coord($fields[$col_names->{start}], $id, \@errors);
        $end   = fix_coord($fields[$col_names->{end}], $id, \@errors) eq 'Unknown'?
            $start : fix_coord($fields[$col_names->{end}], $id, \@errors) ;
    } elsif ( $filetype eq 'common' || $filetype eq 'rare') {
        my $gene_symbol = $fields[$col_names->{'Gene Symbol'}];
        my $PMID = $fields[$col_names->{PMID}];
        my $Unique_ID = $fields[$col_names->{'Unique ID'}];
        $id = $gene_symbol . "|" . $PMID . "|" . $Unique_ID;
        $build = fix_build($fields[$col_names->{build}], $id, \@errors);
        $chr = $fields[$col_names->{Chromosome}];
        $start = fix_coord(
            $fields[$col_names->{"Sequence Position Start"}], $id, \@errors);
        $end = fix_coord(
            $fields[$col_names->{"Sequence Position End"}], $id, \@errors)
            eq 'Unknown' ?
            $start :
            fix_coord($fields[$col_names->{"Sequence Position End"}], $id, \@errors);
    }
    
    ## If all of the components of the REST call are present,
    ##   sanitize the strings by removing spaces and then build the calls.
    if (defined $build     && $build ne '' && $build ne 'Unknown' &&
            defined $chr   && $chr   ne '' &&
            defined $start && $start ne '' &&
            defined $end   && $end   ne '' &&
            defined $id    && $id    ne ''){
        $build =~ s/^\s+|\s+$//g;
        $chr   =~ s/^\s+|\s+$//g;
        $start =~ s/^\s+|\s+$//g;
        $end   =~ s/^\s+|\s+$//g;
        $id    =~ s/^\s+|\s+$//g;
        my $rest_str = $server . "/map/human/" . $build . "/" . $chr . ":" . $start . ".." . $end . "/" . $target_assembly . "?content-type=application/json";
        push @$rest_calls, HTTP::Request->new('GET', $rest_str);
        ## make it easy to retrieve
        ## parallel calls that get
        ## dissociated from the $id
        push @{$calls_hash->{$rest_str}}, $id;
        ## and the other way around for troubleshooting
        $id_2_calls->{$id} = $rest_str;
    } else {
        push @errors, "$id:\tUnable to construct REST request";
    }
}

## Set up the Parallel UserAgent for the REST calls
my $pua = LWP::Parallel::UserAgent->new();
$pua->in_order  (1);  # handle requests in order of registration (0= don't??)
$pua->duplicates(1);  # don't ignore duplicates, though ensembl will reject them
$pua->timeout   (30);  # in seconds
$pua->redirect  (0);  # follow redirects
$pua->max_req   (5); # default is 5
foreach my $rest_call (@$rest_calls) {
    $pua->register($rest_call);
}
my $entries = $pua->wait();


## Get results of REST calls. 
my $retry_calls; ## calls that didn't get a suitable response and need to re-tried
# Get the data into appropriate format
foreach my $entry (sort keys %$entries) {
    my $res = $entries->{$entry}->response;
    my $string = $res->content();
    if ($string eq '') {
        push @$retry_calls, $entries->{$entry}->{request};
        next;
    }
    my $answer;
    try{
        $answer = from_json($string);
    } catch {
        print "Couldn't be changed to json\n";
        $DB::single=1;
        print STDERR $string;
    };
    foreach my $id (@{$calls_hash->{$res->request->url}}) {
        try {
            $data->{$id} = $answer->{mappings};
        } catch {
            print "Could not add $id to data hash\n";
        }
    }
}

foreach my $retry (@$retry_calls) {
    my $ua = LWP::UserAgent::Determined->new;
    my $response = $ua->get($retry->uri);
    if ( $response->is_success) {
        my $answer = from_json($response->content());
        foreach my $id (@{$calls_hash->{$retry->uri}}) {
            $data->{$id} = $answer->{mappings};
        }
    }
}



$DB::single=1;

my $data_json = to_json($data, {pretty=>1, canonical=>1});
open (my $out, ">", $outfile) || die "Couldn't open $outfile\n";
print $out "$data_json";

open (my $error_fh, ">", $errorfile) ;
foreach my $error (@errors) {
    print $error_fh $error . "\n";
}


sub rest_request {
    # modified from
    # https://github.com/Ensembl/ensembl-rest/wiki/Writing-Your-First-Client
    my ($url, $attempts, $message, $success, $filename) = @_;
    $$success = 0;
    $attempts //= 0;
    my $http = HTTP::Tiny->new(("timeout",20));
    my $response = $http->get($url);
    if($response->{success}) {
        my $j = JSON->new->utf8->pretty(1);
        my $json = $response->{content};  # json string
        my $content = $j->decode($json); # change to perl data
        $$success = 1;
        if ( defined( $filename )) {
            open (my $out, ">", $filename);
            print $out $j->encode($content);
            close($out);
        }
        return $content;
    }
    $attempts++;
    my $reason = $response->{reason};
    if($attempts > 3) {
        warn 'Failure with request '.$reason;
        push @$message, "More than 3 attempts at URL $url";
    }
    my $response_code = $response->{status};
    # we were rate limited
    if($response_code == 429) {
        my $sleep_time = $response->{headers}->{'retry-after'};
        sleep($sleep_time);
        return rest_request($url, $attempts, $message);
    }
    push @$message, "Cannot do request at URL $url because of HTTP reason: '${reason}' (${response_code})";
}

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

sub fix_build{
    ## The build field has many free-form strings
    ## They map to standardized strings according the the hash
    ## contained in this function.
    my $raw = shift @_;
    my $id  = shift @_;
    my $errors = shift @_;
    my $replacement = {
        "Build 36"	                        => "NCBI36",
        "Build 36.1/hg18"               	=> "NCBI36",
        "Build 36.3, 2008"               	=> "NCBI36",
        "Build NCBI36/hg18"               	=> "NCBI36",
        "Build36"                           	=> "NCBI36",
        "Build36/hg18"                      	=> "NCBI36",
        "Build37/hg19"                    	=> "GRCh37",
        "Ensembl"                        	=> "Unknown",
        "Ensembl Homo Sapiens v 54.36p, NCBI36"	=> "NCBI36",
        "Ensembl release 50"                	=> "Unknown",
        "GRCh build 37/hg19"              	=> "GRCh37",
        "GRCh36/hg18"                       	=> "NCBI36",
        "GRCh37"                          	=> "GRCh37",
        "GRCh37/hg19"                     	=> "GRCh37",
        "GRCh38"                          	=> "GRCh38",
        "Genome Build 36"                   	=> "NCBI36",
        "Genome Build 36.1"               	=> "NCBI36",
        "Genome assembly May 2004"      	=> "Unknown",
        "Genome build"                  	=> "Unknown",
        "Genome build 36/hg18"             	=> "NCBI36",
        "ISCN 2009"                     	=> "Unknown",
        "N/A"                             	=> "Unknown",
        "N/A (likely hg18)"                 	=> "Unknown",
        "N/A (likely hg19)"                	=> "Unknown",
        "N/A (possibly hg19)"               	=> "Unknown",
        "NA"                             	=> "Unknown",
        "NBCI 36"                         	=> "NCBI36",
        "NCBI"                           	=> "Unknown",
        "NCBI "                         	=> "Unknown",
        "NCBI 36.1/hg18"                   	=> "NCBI36",
        "NCBI Build 35"                  	=> "NCBI35",
        "NCBI Build 35.1"                 	=> "NCBI35",
        "NCBI Build 35/hg17"                	=> "NCBI35",
        "NCBI Build 36"                   	=> "NCBI36",
        "NCBI Build 36.1"               	=> "NCBI36",
        "NCBI Build 36.1/hg18"            	=> "NCBI36",
        "NCBI Build 36.3"                	=> "NCBI36",
        "NCBI Build 36/hg18"              	=> "NCBI36",
        "NCBI Build 37/hg19"             	=> "GRCh37",
        "NCBI Build35"                   	=> "NCBI35",
        "NCBI Build35.1"                  	=> "NCBI35",
        "NCBI Build36"                    	=> "NCBI36",
        "NCBI Build36/hg18"             	=> "NCBI36",
        "NCBI Build37/UCSC hg19"        	=> "GRCh37",
        "NCBI Build37/hg19"               	=> "GRCh37",
        "NCBI Map Viewer"                 	=> "Unknown",
        "NCBI build 37"                   	=> "GRCh37",
        "NCBI build 37/hg19"            	=> "GRCh37",
        "NCBI build37/hg19"             	=> "GRCh37",
        "NCBI/UCSC build 35"              	=> "NCBI35",
        "NCBI34/hg16"                     	=> "NCBI34",
        "NCBI35/hg17"                   	=> "NCBI35",
        "NCBI36"                         	=> "NCBI36",
        "NCBI36.1/hg18"                   	=> "NCBI36",
        "NCBI36/hg18"                       	=> "NCBI36",
        "UCSC 2004"                     	=> "NCBI35",
        "UCSC 2006 Build"                   	=> "NCBI36",
        "UCSC Build 36"                 	=> "NCBI36",
        "UCSC Build 36/hg18"            	=> "NCBI36",
        "UCSC Build35/hg17 (genome assembly May 2004)"	=> "NCBI35",
        "UCSC Build36"                   	=> "NCBI36",
        "UCSC Build36.1"                  	=> "NCBI36",
        "UCSC Build36/hg18"             	=> "NCBI36",
        "UCSC GRCh37"                   	=> "GRCh37",
        "UCSC Genome Browser"           	=> "Unknown",
        "UCSC Genome Browser 2006/hg18 build"	=> "NCBI36",
        "UCSC Genome Browser Build 36.1"	=> "NCBI36",
        "UCSC Genome Browser Build36"       	=> "NCBI36",
        "UCSC Genome Browser March 2006"	=> "NCBI36",
        "UCSC Genome Browser March 2006 (hg18) assembly"	=> "NCBI36",
        "UCSC Genome Browser build37"    	=> "GRCh37",
        "UCSC Genome Browser hg18"      	=> "NCBI36",
        "UCSC Human Genome May 2004 assembly"	=> "NCBI35",
        "UCSC Mar. 2006 Assembly (NCBI Build36/hg18)"	=> "NCBI36",
        "UCSC March 2006"               	=> "NCBI36",
        "UCSC March 2006 Human Genome Build (NCBI36/hg18)"	=> "NCBI36",
        "UCSC March 2006 assembly/hg18"	        => "NCBI36",
        "UCSC March 2006/hg18"             	=> "NCBI36",
        "UCSC May 2004 (NCBI 35/hg17)"         	=> "NCBI35",
        "UCSC May 2004 assembly"        	=> "NCBI35",
        "UCSC May 2004/hg17"            	=> "NCBI35",
        "UCSC NCBI36/hg18"              	=> "NCBI36",
        "UCSC genome browser, 2011"      	=> "GRCh37",
        "UCSC hg18"                     	=> "NCBI36",
        "UCSC hg18/NCBI Build 36"       	=> "NCBI36",
        "UCSC hg19"                     	=> "GRCh37",
        "UCSC hg19/build 37"              	=> "GRCh37",
        "UCSC36/hg18"                     	=> "NCBI36",
        "hg17"                            	=> "NCBI35",
        "hg18"                           	=> "NCBI36",
        "hg18 genome assembly"              	=> "NCBI36",
        "hg18/Build 36"                    	=> "NCBI36",
        "hg18/NCBI 36.1"                 	=> "NCBI36",
        "hg18/NCBI Build36.1"              	=> "NCBI36",
        "hg18/NCBI build 36"               	=> "NCBI36",
        "hg18/NCBI build 36.1"            	=> "NCBI36",
        "hg19"                           	=> "GRCh37",
    };
    
    if( exists $replacement->{$raw}){
        return $replacement->{$raw};
    } else {
        push @$errors, "$id:\tno known standardized genome build";
        return 'Unknown';
    }
}
    
    
            __END__

=head1 NAME

convert_to_grch38.pl - Get GRCh38 coordinates from previous builds. 

=head1 SYNOPSIS

 convert_to_grch38.pl --infile infile.txt
                      --outfile outfile.json
                      --errorfile errorfile.errors
                      --filetype rare | common | cnv
                      --target_assembly GRCh38

convert_to_grch38 --help    for complete documentation

The output of this script can be processed by conversion_stats.pl
and grch38_to_excel.pl

=head1 OPTIONS

=over

=item B<-h --help>

Print this message

=item B<-i --infile>

A text file delimited by pipes '|'. The exact format of this file is
hard-coded here and identified by the B<filetype> parameter
because the format is stable in MindSpec's pipeline.
However, recoding this is simple, if necessary.

=item B<-o --outfile>

A json text file

=item B<-f --filetype>

Possible values are 'common', 'rare', or 'cnv'. All of these are text files
generated by MindSpec's pipeline (as communicated by Wayne P.) but differ on
the columns they contain and the columns' location. 

=item B<-e --errorfile>

File into which errors are printed

=item B<-t --target_assembly>

Assembly number to which liftover is done. Usually GRCh38 until that
becomes obsolete.

=back

=head1 DESCRIPTION

The output file will look like:

 {
   "GEN230R005" : [
      {
         "mapped" : {
            "assembly" : "GRCh38",
            "coord_system" : "chromosome",
            "end" : 50674675,
            "seq_region_name" : "22",
            "start" : 50674675,
            "strand" : 1
         },
         "original" : {
            "assembly" : "GRCh37",
            "coord_system" : "chromosome",
            "end" : 51113103,
            "seq_region_name" : "22",
            "start" : 51113103,
            "strand" : 1
         }
      }
   ]
 }

with 'GEN...' being the Unique Key assigned by MindSpec. Depending on the
type of data (CNV vs Human gene module variants), the key is constructed
based on concatenating other fields.

Variants that map
to more than a single region on GRCh38 are located in the GEN... array.

=head1 SEE ALSO

=head1 AUTHOR

Senanu Spring-Pearson Senanu.Pearson --at-- gmail.com

=cut
