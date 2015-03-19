#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

pass=$1
xmlfile=$2
annotation=$3
is_test=$4
quiet=$5

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
dbname=${LRGDBNAMETEST}
if [[ -z ${is_test} || ${is_test} == 0 ]] ; then
  dbname=${LRGDBNAME}
fi
perldir=${CVSROOTDIR}/lrg-code/scripts/pipeline



hgnc=`lrg_gene_name ${xmlfile}`

if [ -z ${quiet} ]
then
  echo -n "Will update the ${dbname} database ${annotation} annotation_set with the one specified in ${xmlfile} (${hgnc}), using scripts in ${perldir}, correct (y/n)? "
  read -e go
  [ $go == "y" ] || exit
fi

outfile=${xmlfile}.new

echo "Updating database..."
perl ${perldir}/lrg2db.pl -host ${host} -port ${port} -user ${user} -pass ${pass} -dbname ${dbname} -replace_updatable ${annotation} -xmlfile ${xmlfile} -hgnc_symbol ${hgnc}
echo "Re-generating xml file..."
perl ${perldir}/db2lrg.pl -host ${host} -port ${port} -user ${user} -pass ${pass} -dbname ${dbname} -include_external -xmlfile ${outfile} -hgnc_symbol ${hgnc}

echo "A new LRG XML file for ${hgnc}, generated from the data in the database has been saved to ${outfile}"
