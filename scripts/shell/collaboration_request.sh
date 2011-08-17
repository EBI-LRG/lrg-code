#! /bin/bash
. ~/.lrgpaths

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBROUSER}
dbname=${LRGDBNAME}
perldir=${CVSROOTDIR}/code/scripts/

args=""
for arg in $*
do
  if [[ ${arg} == -* ]]
  then
    let args="${args} ${arg}"
  else
    let args="${args} '${arg}'"
  fi
done

echo ${perldir}/collaboration_request.pl -host ${host} -port ${port} -user ${user} -pass "" -dbname ${dbname} ${args}
