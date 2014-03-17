#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
dbname=${LRGDBNAME}
pass=${LRGDBPASS}
perldir=${CVSROOTDIR}/lrg-code/scripts/

xmlfile=$1
filename=`basename ${xmlfile}`
lrgid=${filename/.xml.new/}
hgnc=$2
error_log=$3
warning=$4

# Use the value "none" for warning, if you want to skip the check of the polyA between the RefSeq transcript sequences and the LRG transcript sequences

echo "Importing ${lrgid} into db..."
perl ${perldir}/lrg2db.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -lrg_id ${lrgid} -purge -verbose
perl ${perldir}/lrg2db.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -xmlfile ${xmlfile} -lrg_id ${lrgid} -hgnc_symbol ${hgnc} -verbose -error_log ${error_log} -warning ${warning}

