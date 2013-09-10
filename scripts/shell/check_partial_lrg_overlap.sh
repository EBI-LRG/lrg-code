#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

perldir=${CVSROOTDIR}/code/scripts/


xmldir=$1
assembly=$2
lrglist=$3

if [[ -n ${lrglist} ]] ; then
  lrglist="-datalist ${lrglist}"
else
  lrglist=''
fi

echo "> Checking if LRG data partially overlaps the Ensembl annotations" >&2 
perl ${perldir}/check_partial_lrg_overlap.pl -xmldir ${xmldir} -assembly ${assembly} ${lrglist}

