#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

perldir=${LRGROOTDIR}/lrg-code/scripts/pipeline
hashdir=${HASHDIR}
tmpdir=${TMPDIR}

xmlfile=$1
registryfile=$2

filename=`basename ${xmlfile}`
lrgid=${filename/.xml/}
outfile=${xmlfile}.mapped

echo "LRG sequence in ${xmlfile} will be mapped using hashes in ${hashdir} and perl scripts in ${perldir}..."  

perl ${perldir}/make.lrg.pl -xml_template ${xmlfile} -registry_file ${registryfile} -out ${outfile} -id ${lrgid} -target_dir ${hashdir} -tmpdir ${tmpdir} -skip_fixed -skip_host_check

echo "An updated LRG XML file for ${lrgid} has been written to ${outfile}"

