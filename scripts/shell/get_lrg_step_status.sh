#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass


output=$1
private=$2
is_test=$3

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
dbname=${LRGDBNAMETEST}
if [[ -z ${is_test} || ${is_test} == 0 ]] ; then
  dbname=${LRGDBNAME}
fi
pass=${LRGDBPASS}
perldir=${CVSROOTDIR}/lrg-code/scripts/



tmpdir=${CVSROOTDIR}

if [[ -n "${private}" && ${private} != 0 ]]; then
	private="-private"
else
  private=""
fi

perl ${perldir}/get_lrg_step_status.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -output ${output} -tmpdir ${tmpdir} ${private}
