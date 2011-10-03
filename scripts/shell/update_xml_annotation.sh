#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

perldir=${CVSROOTDIR}/code/scripts/

xmlfile=$1
registryfile=${REGISTRYFILE}
mapping=$2

filename=`basename ${xmlfile}`
lrgid=${filename/.xml/}
outfile=${xmlfile}.new
target_dir=${SEQDIR}
tmpdir=${TMPDIR}

echo "Ensembl annotations in ${xmlfile} will be re-generated using the registry configuration in ${registryfile} and perl scripts in ${perldir}..."  

command="perl ${perldir}/make.lrg.pl -xml_template ${xmlfile} -registry_file ${registryfile} -out ${outfile} -id ${lrgid} -skip_fixed -replace_annotations -skip_host_check"

if [ -n "${mapping}" ]
then
  command=${command}" -target_dir ${target_dir} -tmpdir ${tmpdir}"
else
  command=${command}" -use_existing_mapping"
fi

$command

echo "An updated LRG XML file for ${lrgid} has been written to ${outfile}"

