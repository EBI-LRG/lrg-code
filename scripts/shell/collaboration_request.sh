#! /bin/bash
. ~/.lrgpaths

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBROUSER}
dbname=${LRGDBNAME}
perldir=${CVSROOTDIR}/code/scripts/

perl ${perldir}/collaboration_request.pl -host ${host} -port ${port} -user ${user} -pass "" -dbname ${dbname} $*
