#! /bin/bash
. ~/.lrgpaths

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBROUSER}
dbname=${LRGDBNAME}
perldir=${CVSROOTDIR}/code/scripts/

addressee=""
lrg_id=""
symbol=""
i=1

for arg in "$@"
do
  if [[ ${i} == 1 ]]
  then
    addressee=${arg}
  else
    if [[ ${arg} == LRG* ]]
    then
      lrg_id="${lrg_id}-lrg_id ${arg} "
    else
      symbol="${symbol}-symbol ${arg} "
    fi
  fi
  let i=i+1
done

perl ${perldir}/collaboration_request.pl -host ${host} -port ${port} -user ${user} -pass '' -dbname ${dbname} -addressee "${addressee}" ${lrg_id} ${symbol}
