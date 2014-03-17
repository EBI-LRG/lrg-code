#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
dbname=${LRGDBNAME}
perldir=${CVSROOTDIR}/lrg-code/scripts/

inputfile=$1
pass=7Ntoz3HH
verbose=""
if [[ $2 ]]; then
  verbose='-verbose'
fi


perl ${perldir}/create_db_lsdb_gene_contact_links.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -inputfile ${inputfile} ${verbose}


