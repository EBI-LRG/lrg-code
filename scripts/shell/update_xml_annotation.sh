#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

perldir=${CVSROOTDIR}/code/scripts/

xmlfile=$1
locus=$2
assembly=$3

tmpfile=${xmlfile}.tmp
outfile=${xmlfile}.new

echo "Creating the LRG annotation set and moving ${assembly} assembly mappings"
perl ${perldir}/add_LRG_annotation_set.pl -xmlfile ${xmlfile} -locus ${locus} -assembly ${assembly} -replace > ${tmpfile}

echo "Adding Ensembl annotation set to ${xmlfile}"
perl ${perldir}/add_ensembl_annotation.pl -xmlfile ${tmpfile} -assembly ${assembly} -replace > ${outfile}

rm ${tmpfile}

echo "An updated LRG XML file has been written to ${outfile}"

