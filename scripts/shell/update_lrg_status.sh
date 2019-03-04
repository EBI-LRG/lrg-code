#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass


status=$1
lrg_id=$2
dbname=$3

gitpath=${LRGROOTDIR}
perldir=${gitpath}/lrg-code/scripts/pipeline

# Database settings
host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
pass=${LRGDBPASS}

if [[ -n $status && -n $lrg_id && -n $dbname ]];then
  `perl ${perldir}/update_lrg_status.pl -lrg_id ${lrg_id} -status ${status} -host ${host} -dbname ${dbname} -port ${port} -user ${user} -pass ${pass}`
else
  echo "Missing LRG ID, LRG status or LRG database name"
fi
