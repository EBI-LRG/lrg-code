#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass

inputfile=$1
lrgid=$2
is_test=$3

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
dbname=${LRGDBNAMETEST}
if [[ -z ${is_test} || ${is_test} == 0 ]] ; then
  dbname=${LRGDBNAME}
fi
pass=${LRGDBPASS}
perldir=${CVSROOTDIR}/lrg-code/scripts/


echo "Importing ${lrgid} other exon naming into db..."
perl ${perldir}/parse_other_exon.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -input_file ${inputfile} -lrg_id ${lrgid} -replace

