#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBROUSER}
dbname='lrg'
dir=${PUBFTP}/.lrg_internal
perldir=${CVSROOTDIR}/lrg-code/scripts/

tmpdir=''
tmp=$1

if [ ${tmp} ]; then
  tmpdir="-tmp_dir ${tmp}"
else
  tmpdir="-tmp_dir ${CVSROOTDIR}"
fi

perl ${perldir}/get_status_from_db.pl -host ${host} -port ${port} -user ${user} -pass "" -dbname ${dbname} -dir ${dir} ${tmpdir}

