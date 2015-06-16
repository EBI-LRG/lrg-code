#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass

# Relevant paths
path=$1
pass=${LRGDBPASS}

if [[ ${path} ]] ; then
  mysqldump -h ${LRGDBHOST} -P ${LRGDBPORT} -u ${LRGDBADMUSER} -p${pass} lrg | gzip > "$1/lrg_dump_"`date +%d`.sql.gz
else
  echo "No directory given as argument!"
fi

