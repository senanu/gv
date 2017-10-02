#!/bin/bash

# Where are files stored?

# Three files directly from AutDB:
# Common Table from Human Gene Module
# Rare Table from Human Gene Module
# Individual Table from CNV Module
# All should be pipe-delimited text files and should contain GRCh38 coordinates.
# GRCh38 coords should be in fields named either 'start_GRCh38', 'end_GRCh38',
# and 'chr_GRCh38' or 'chr', 'start', 'end'. However, since Fall 2017,
# all GRCh38 coordinates should be labeled according to the former scheme.
COMMONVARS="/Users/senanu/Desktop/mindspec/data/processed/HG_common_Q2_2017.csv"
RAREVARS="/Users/senanu/Desktop/mindspec/data/processed/HG_rare_Q2_2017.csv"
CNVVARS="/Users/senanu/Desktop/mindspec/data/processed/CNV_Individual_Q2_2017.csv"

# Directory name in which to to temporarily hold data
# This directory will be deleted at the end of the script, so make sure
# it doesn't point to anything important, because it will be deleted!
DATADIR="../data"
HGFILE="temp_HG.json"
CNVFILE="temp_CNV.json"

# Final data repository
GENOVERSEDATADIR="../Genoverse_Data"

###-----------------------------------------------------###
###    Modifications should not be needed below this    ###
###    point for simple filesystem specifications       ###
###-----------------------------------------------------###


mkdir $DATADIR

# Convert the pipe-delimited text files to json files
./txt2json.pl  -i $COMMONVARS -i $RAREVARS -o $DATADIR/$HGFILE -d "|"
./txt2json.pl -i $CNVVARS -o $DATADIR/$CNVFILE -d "|"

# Delete many of the fields that Eric suggested (11/5/2015) to keep only these.
# Note that if this is changed, make sure the change is OK for both the
# common and rare variants files, which are, by now, combined.
perl -ni -e 'print if /\{|\}|\[|\]|Unique ID|Variant-disorder association|Allele Change|Residue Change|Variant Evidence|SNP|Mutation Type Details|Variant Stat|Variant Function|start_GRCh38|end_GRCh38|chr_GRCh38|PMID/' $DATADIR/$HGFILE
# Delete fields except these:
# Note that these are Senanu's suggestions, but did not come from Eric.
perl -ni -e 'print if /\{|\}|\[|\]|CNV inheritance|CNV type|CNV-disease segregation|Case\/control|Clinical profile|Cognitive profile|Family profile|PMID|Patient ID|Patient age|Patient gender|Primary diagnosis|Primary disorder inheritance|chr_GRCh38|end_GRCh38|start_GRCh38/' $DATADIR/$CNVFILE

# Genoverse requires that the field that is colored does not have spaces,
# so use underscores
sed -i '' 's/Mutation\ Type\ Details/Mutation_Type_Details/' $DATADIR/$HGFILE
sed -i '' 's/Mutation\ Type\ Details/Mutation_Type_Details/' $DATADIR/$CNVFILE

# Convert Unique ID to 'ID' so that Genoverse can use it as a label for the
# variant. This is only relevant to HG module files, since CNV module doesn't
# have a convenient ID field
sed -i '' 's/Unique\ ID/ID/' $DATADIR/$HGFILE

# delete the "_GRCh38" off the end of the chr, start, and end strings
sed -i '' 's/_GRCh38//' $DATADIR/$HGFILE
sed -i '' 's/_GRCh38//' $DATADIR/$CNVFILE
sed -i '' 's/CNV type/CNV_type/' $DATADIR/$CNVFILE

# Divide the data into chromosomes and move it into position
mkdir $GENOVERSEDATADIR
./divide_by_chr.pl -i $DATADIR/$HGFILE -o $GENOVERSEDATADIR/SNP_
./divide_by_chr.pl -i $DATADIR/$CNVFILE -o $GENOVERSEDATADIR/CNV_

# Clean up
rm -fr $DATADIR
