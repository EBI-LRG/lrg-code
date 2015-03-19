#! /bin/bash
. ~/.lrgpaths

lrgid=$1
outfile=$2
is_test=$3

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBROUSER}
dbname=${LRGDBNAMETEST}
if [[ -z ${is_test} || ${is_test} == 0 ]] ; then
  dbname=${LRGDBNAME}
fi
perldir=${CVSROOTDIR}/lrg-code/scripts/pipeline

spec="-lrg_id ${lrgid}"

if [ -z ${outfile} ]
then
    outfile=${lrgid}.xml.exp
fi

echo "Generating xml file..."
perl ${perldir}/db2lrg.pl -host ${host} -port ${port} -user ${user} -pass "" -dbname ${dbname} -include_external -xmlfile ${outfile} ${spec}

echo "A new LRG XML file for "`lrg_gene_name ${outfile}`", generated from the data in the database has been saved to ${outfile}"
