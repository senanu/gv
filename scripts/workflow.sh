#!/bin/bash
DATA="../data" ## Data directory 
# Do the conversion, storing the results in a json file
# This step can be long, so only do it if the output file doesn't exist
if [ ! -e $DATA/HG_common.json ]
then
    (./convert_to_grch38.pl -i $DATA/HG_Sequence_Var_Common_Data.txt -o $DATA/HG_common.json -f common -e $DATA/HG_common.errors -t GRCh38)&
fi
if [ ! -e $DATA/HG_rare.json ]
then 
    (./convert_to_grch38.pl -i $DATA/HG_Sequence_Var_Rare_Data.txt -o $DATA/HG_rare.json -f rare -e $DATA/HG_rare.errors -t GRCh38)&
fi
if [ ! -e $DATA/CNV_Individual.json ]
then
    (./convert_to_grch38.pl -i $DATA/CNV_Individual_Data.txt -o $DATA/CNV_Individual.json -f cnv -e $DATA/CNV_Individual.errors -t GRCh38)&
fi
wait


# Get rid of the 1978-09-07 that appears at the end of each file
sed -i '' s/\|1978-09-07// $DATA/HG_Sequence_Var_Common_Data.txt
sed -i '' s/\|1978-09-07// $DATA/HG_Sequence_Var_Rare_Data.txt
sed -i '' s/\|1978-09-07// $DATA/CNV_Individual_Data.txt

# update the data file with the results of the conversion
./add_new_build_data.pl -i $DATA/HG_Sequence_Var_Common_Data.txt -m $DATA/HG_common.json -f common -o $DATA/HG_common.txt -h
./add_new_build_data.pl -i $DATA/HG_Sequence_Var_Rare_Data.txt -m $DATA/HG_rare.json -f rare -o $DATA/HG_rare.txt -h
./add_new_build_data.pl -i $DATA/CNV_Individual_Data.txt -m $DATA/CNV_Individual.json -f cnv -o $DATA/CNV_Individual.txt -h

# Filter to separate the clean and dirty variants
./filter_variants.pl -i $DATA/HG_common.txt -h -f common -o $DATA/HG_common_clean.txt -d $DATA/HG_common_dirty.txt
./filter_variants.pl -i $DATA/HG_rare.txt -h -f rare -o $DATA/HG_rare_clean.txt -d $DATA/HG_rare_dirty.txt
./filter_variants.pl -i $DATA/CNV_Individual.txt -h -f cnv -o $DATA/CNV_Individual_clean.txt -d $DATA/CNV_Individual_dirty.txt

# Get it into json format
./txt2json.pl -i $DATA/HG_common_clean.txt -f common -o $DATA/HG_common_clean.json -h
./txt2json.pl -i $DATA/HG_rare_clean.txt -f rare -o $DATA/HG_rare_clean.json -h
./txt2json.pl -i $DATA/CNV_Individual_clean.txt -f cnv -o $DATA/CNV_Individual_clean.json -h

# Delete many of the fields that Eric suggested (11/5/2015) to keep only these:
perl -ni -e 'print if /\{|\}|\[|\]|Unique ID|Variant-disorder association|variant_type|Allele Change|Residue Change|Variant Evidence|Variant Stats|Variant Function|start|end|chr|external_link|AutDB_link|pubmed/' $DATA/HG_common_clean.json
perl -ni -e 'print if /\{|\}|\[|\]|Unique ID|Variant-disorder association|variant_type|Allele Change|Residue Change|Variant Evidence|Variant Stats|Variant Function|start|end|chr|external_link|AutDB_link|pubmed/' $DATA/HG_rare_clean.json

# Combine all three data sources, then divide them up by size
./remix_by_size.pl -i $DATA/HG_common_clean.json  -i $DATA/HG_rare_clean.json -i $DATA/CNV_Individual_clean.json -s $DATA/SNP.json -c $DATA/CNV.json

# delete the "_GRCh38" off the end of the chr, start, and end strings
sed -i '' s/start_GRCh38/start/ $DATA/SNP.json
sed -i '' s/start_GRCh38/start/ $DATA/CNV.json
sed -i '' s/end_GRCh38/end/ $DATA/SNP.json
sed -i '' s/end_GRCh38/end/ $DATA/CNV.json
sed -i '' s/chr_GRCh38/chr/ $DATA/SNP.json
sed -i '' s/chr_GRCh38/chr/ $DATA/CNV.json
sed -i '' /start_end_mapped_GRCh38/d $DATA/SNP.json
sed -i '' /start_end_mapped_GRCh38/d $DATA/CNV.json

# Get rid of pubmed and replace it with PMID
sed -i '' s/pubmed/PMID/ $DATA/SNP.json
sed -i '' s/pubmed/PMID/ $DATA/CNV.json

# Divide the data into chromosomes and move it into position
mkdir ../Genoverse_Data
./divide_by_chr.pl -i $DATA/SNP.json -o ../Genoverse_Data/SNP_
./divide_by_chr.pl -i $DATA/CNV.json -o ../Genoverse_Data/CNV_
mv ../Genoverse_Data/* ../../Genoverse/data/
