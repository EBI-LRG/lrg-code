#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass

inputfile=$1
is_test=$2
verbose=""
if [[ $3 ]]; then
  verbose='-verbose'
fi

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
dbname=${LRGDBNAMETEST}
if [[ -z ${is_test} || ${is_test} == 0 ]] ; then
  dbname=${LRGDBNAME}
fi
pass=${LRGDBPASS}
perldir=${LRGROOTDIR}/lrg-code/scripts/


perl ${perldir}/create_db_lsdb_gene_contact_links.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -inputfile ${inputfile} ${verbose}


