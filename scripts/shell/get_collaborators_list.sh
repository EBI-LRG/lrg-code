#! /bin/bash
. ~/.bashrc
. ~/.lrgpass

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBROUSER}
dbname=${LRGDBNAME}
pass=${LRGDBPASS}
perldir=${LRGROOTDIR}/lrg-code/scripts/

perl ${perldir}/collaborators_list.pl -host ${host} -user ${user} -port ${port} -dbname ${dbname}
