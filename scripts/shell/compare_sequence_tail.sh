#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass

xmlfile=$1
is_test=$2
error_log=$3
warning_log=$4
silent=$5

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
dbname=${LRGDBNAMETEST}
if [[ -z ${is_test} || ${is_test} == 0 ]] ; then
  dbname=${LRGDBNAME}
fi
pass=${LRGDBPASS}
perldir=${LRGROOTDIR}/lrg-code/scripts/pipeline/



if [[ -n ${warning_log} && ${warning_log} != 0 ]] ; then
  warning_log="-warning_log ${warning_log}"
fi

# Use the value "none" for warning, if you want to skip the check of the polyA between the RefSeq transcript sequences and the LRG transcript sequences
if [[ ${silent} ]]; then
  verbose=''
else 
  echo "Compare ${lrgid} transcripts tail sequences with RefSeq sequences..."
  verbose='-verbose'
fi  
perl ${perldir}/compare_sequence_tail.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -xmlfile ${xmlfile} ${verbose} -error_log ${error_log} ${warning_log}

