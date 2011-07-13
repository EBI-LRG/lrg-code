#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

perldir=${CVSROOTDIR}/code/scripts/

xmlfile=$1
registryfile=$2

filename=`basename ${xmlfile}`
lrgid=${filename/.xml/}
outfile=${xmlfile}.new

echo "Ensembl annotations in ${xmlfile} will be re-generated using the registry configuration in ${registryfile} and perl scripts in ${perldir}..."  

perl ${perldir}/make.lrg.pl -xml_template ${xmlfile} -registry_file ${registryfile} -out ${outfile} -id ${lrgid} -skip_fixed -replace_annotations -use_existing_mapping -skip_host_check -skip_transcript_matching 

echo "An updated LRG XML file for ${lrgid} has been written to ${outfile}"

