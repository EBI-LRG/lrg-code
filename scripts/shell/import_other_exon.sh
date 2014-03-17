#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
dbname=${LRGDBNAME}
pass=${LRGDBPASS}
perldir=${CVSROOTDIR}/lrg-code/scripts/

inputfile=$1
lrgid=$2


echo "Importing ${lrgid} other exon naming into db..."
perl ${perldir}/parse_other_exon.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -input_file ${inputfile} -lrg_id ${lrgid} -replace

