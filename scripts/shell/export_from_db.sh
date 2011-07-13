#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBROUSER}
dbname=${LRGDBNAME}
perldir=${CVSROOTDIR}/code/scripts/
lrgid=$1
hgnc_symbol=$2
outfile=$3

if [ -z ${lrgid} ]
then
  spec="-hgnc_symbol ${hgnc_symbol}"
  lrgid=${hgnc_symbol}
else
  spec="-lrg_id ${lrgid}"
fi

if [ -z ${outfile} ]
then
    outfile=${lrgid}.xml.exp
fi

echo "Generating xml file..."
perl ${perldir}/db2lrg.pl -host ${host} -port ${port} -user ${user} -pass "" -dbname ${dbname} -include_external -xmlfile ${outfile} ${spec}

echo "A new LRG XML file for "`lrg_gene_name ${outfile}`", generated from the data in the database has been saved to ${outfile}"
