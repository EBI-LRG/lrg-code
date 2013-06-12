#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
dbname=${LRGDBNAME}
perldir=${CVSROOTDIR}/code/scripts/

xmlfile=$1
pass=$2
error_log=$3

# Use the value "none" for warning, if you want to skip the check of the polyA between the RefSeq transcript sequences and the LRG transcript sequences

echo "Compare ${lrgid} transcripts tail sequences with RefSeq sequences..."
perl ${perldir}/compare_sequence_tail.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -xmlfile ${xmlfile} -verbose -error_log ${error_log}

