#! /bin/bash
. ~/.lrgpaths

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBROUSER}
dbname=${LRGDBNAME}
dir=${PUBFTP}/.lrg_internal
perldir=${CVSROOTDIR}/code/scripts/

tmpdir=''
tmp=$1

if [ ${tmp} ]; then
  tmpdir="-tmp_dir ${tmp}"
else
  tmpdir="-tmp_dir ${CVSROOTDIR}"
fi

echo "Generating LRG status report ..."
perl ${perldir}/get_status_from_db.pl -host ${host} -port ${port} -user ${user} -pass "" -dbname ${dbname} -dir ${dir} ${tmpdir}

echo "A new LRG status report file has been generated from the lrg status in the database at the following location: ${dir}"
