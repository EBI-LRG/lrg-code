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
lrgid=${filename/.xml/}
hgnc=`lrg_gene_name ${xmlfile}`

echo "Importing ${lrgid} into db..."
perl ${perldir}/lrg2db.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -lrg_id ${lrgid} -purge
perl ${perldir}/lrg2db.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -xmlfile ${xmlfile} -lrg_id ${lrgid} -hgnc_symbol ${hgnc}
