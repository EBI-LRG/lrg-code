#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

# Relevant paths
path=$1

if [[ ${path} ]] ; then
  /nfs/dbtools/mysql/5.6/usr/bin/mysqldump -h ${LRGDBHOST} -P ${LRGDBPORT} -u ${LRGDBROUSER} ${LRGDBNAME} --lock-tables=false | gzip > "$1/lrg_dump_"`date +%d`.sql.gz
else
  echo "No directory given as argument for the MySQL dump script!"
fi

