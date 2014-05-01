#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
dbname=${LRGDBNAME}
pass=${LRGDBPASS}
perldir=${CVSROOTDIR}/lrg-code/scripts/

output=$1
private=$2

if [[ -n "${private}" ]]; then
	private="-private"
else
  private=""
fi

perl ${perldir}/get_lrg_step_status.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -output ${output} ${private}
