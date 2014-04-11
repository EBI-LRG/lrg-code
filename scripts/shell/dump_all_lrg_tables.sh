#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass

# Relevant paths
path=$1
pass=${LRGDBPASS}

if [[ ${path} ]] ; then
  mysqldump -h ${LRGDBHOST} -P ${LRGDBPORT} -u ${LRGDBADMUSER} -p${pass} lrg > "$1/lrg_dump_"`date +%d`.sql
else
  echo "No directory given as argument!"
fi

