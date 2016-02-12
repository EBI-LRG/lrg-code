#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass


output=$1
private=$2

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
dbname=${LRGDBNAME}

pass=${LRGDBPASS}
perldir=${LRGROOTDIR}/lrg-code/scripts/


if [[ -n "${private}" && ${private} != 0 ]]; then
	private="-private"
else
  private=""
fi

perl ${perldir}/get_lrg_step_status.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -output ${output} ${private}
