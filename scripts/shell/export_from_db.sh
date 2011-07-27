#! /bin/bash
. ~/.lrgpaths

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBROUSER}
dbname=${LRGDBNAME}
perldir=${CVSROOTDIR}/code/scripts/
lrgid=$1
outfile=$2
spec="-lrg_id ${lrgid}"

if [ -z ${outfile} ]
then
    outfile=${lrgid}.xml.exp
fi

echo "Generating xml file..."
perl ${perldir}/db2lrg.pl -host ${host} -port ${port} -user ${user} -pass "" -dbname ${dbname} -include_external -xmlfile ${outfile} ${spec}

echo "A new LRG XML file for "`lrg_gene_name ${outfile}`", generated from the data in the database has been saved to ${outfile}"
