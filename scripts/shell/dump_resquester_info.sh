#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

output_file=$1
is_test=$2

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBROUSER}
dbname=${LRGDBNAMETEST}
if [[ -z ${is_test} || ${is_test} == 0 ]] ; then
  dbname=${LRGDBNAME}
fi
perldir=${LRGROOTDIR}/lrg-code/scripts/


echo "Dumping request data from the LRG database ..."
perl ${perldir}/dump_request_info.pl -host ${host} -user ${user} -port ${port} -dbname ${dbname} -output_file ${output_file} -verbose
echo "done!"
