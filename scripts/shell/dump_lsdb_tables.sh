#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

# Relevant paths
path=$1
pass=7Ntoz3HH

if [[ ${path} ]] ; then
  mysqldump -h ${LRGDBHOST} -P ${LRGDBPORT} -u ${LRGDBADMUSER} -p${pass} lrg gene requester lsdb lsdb_contact lsdb_gene lrg_request lrg_status lrg_status_backup > "$1/lrg_dump_"`date +%d`.sql
else
  echo "No directory given as argument!"
fi


