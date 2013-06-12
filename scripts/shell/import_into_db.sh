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

filename=`basename ${xmlfile}`
lrgid=${filename/.xml.new/}
hgnc=$3
error_log=$4
warning=$5

# Use the value "none" for warning, if you want to skip the check of the polyA between the RefSeq transcript sequences and the LRG transcript sequences

echo "Importing ${lrgid} into db..."
perl ${perldir}/lrg2db.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -lrg_id ${lrgid} -purge -verbose
perl ${perldir}/lrg2db.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -xmlfile ${xmlfile} -lrg_id ${lrgid} -hgnc_symbol ${hgnc} -verbose -error_log ${error_log} -warning ${warning}

