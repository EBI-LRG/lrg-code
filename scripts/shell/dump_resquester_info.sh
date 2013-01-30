#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBROUSER}
dbname='lrg' #dbname=${LRGDBNAME}
perldir=${CVSROOTDIR}/code/scripts/

output_file=$1

echo "Dumping request data from the LRG database ..."
perl ${perldir}/dump_request_info.pl -host ${host} -user ${user} -port ${port} -dbname ${dbname} -output_file ${output_file} -verbose
echo "done!"
