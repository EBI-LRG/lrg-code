#! /bin/bash
. ~/.lrgpaths

input=$1
is_test=$2

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBROUSER}
dbname=${LRGDBNAMETEST}
if [[ -z ${is_test} || ${is_test} == 0 ]] ; then
  dbname=${LRGDBNAME}
fi

symbols=""
# If the input is a file, parse it (expecting one HGNC symbol per line)
if [[ -f ${input} && -e ${input} ]]
then
  while read hgnc
  do
    symbols="$symbols${hgnc} "
  done < ${input}
else
  for hgnc in "$@"
  do
    symbols="$symbols${hgnc} "
  done
fi

query="SELECT IFNULL(g.lrg_id,'') FROM gene g WHERE g.symbol LIKE 'HGNC_SYMBOL'"
for hgnc in ${symbols}
do
  echo "${hgnc}"$'\t'`echo "${query/HGNC_SYMBOL/${hgnc}}" | mysql --skip-column-names -u ${user} -P ${port} -h ${host} ${dbname}`
done
