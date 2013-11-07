#! /bin/bash
. ~/.lrgpaths

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBROUSER}
dbname=${LRGDBNAME}
dir=${PUBFTP}/.lrg_internal
perldir=${CVSROOTDIR}/code/scripts/

echo "Generating LRG status report ..."
perl ${perldir}/get_status_from_db.pl -host ${host} -port ${port} -user ${user} -pass "" -dbname ${dbname} -dir ${dir}

echo "A new LRG status report file has been generated from the lrg status in the database at the following location: ${dir}"
