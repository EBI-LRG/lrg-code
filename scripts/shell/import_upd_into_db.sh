#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass

xmlfile=$1
filename=`basename ${xmlfile}`
lrgid=${filename/.xml.new/}
hgnc=$2
is_test=$3
error_log=$4
warning=$5

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
dbname=${LRGDBNAMETEST}
if [[ -z ${is_test} || ${is_test} == 0 ]] ; then
  dbname=${LRGDBNAME}
fi
pass=${LRGDBPASS}
perldir=${CVSROOTDIR}/lrg-code/scripts/pipeline


# Use the value "none" for warning, if you want to skip the check of the polyA between the RefSeq transcript sequences and the LRG transcript sequences

echo "Importing ${lrgid} into db..."
perl ${perldir}/lrg2db.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -lrg_id ${lrgid} -purge -verbose -only_updatable_data
perl ${perldir}/lrg2db.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -xmlfile ${xmlfile} -lrg_id ${lrgid} -hgnc_symbol  ${hgnc} -verbose -error_log ${error_log} -warning ${warning} -only_updatable_data

