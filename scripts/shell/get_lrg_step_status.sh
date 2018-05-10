#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass


output=$1
website=$2
private=$3

host=${LRGDBHOST}
port=${LRGDBPORT}
user=${LRGDBADMUSER}
dbname=${LRGDBNAME}

ftp_dir=${PUBFTP}/.lrg_index/

pass=${LRGDBPASS}
perldir=${LRGROOTDIR}/lrg-code/scripts/

copy_output_file=0

# website=1 => generate website output + copy to website
# website=2 => generate website output only
if [[ -n "${website}" && ${website} != 0 ]]; then
  copy_output_file=${website}
	website="-website"
else
  website=""
fi

if [[ -n "${private}" && ${private} != 0 ]]; then
	private="-private"
else
  private=""
fi

perl ${perldir}/get_lrg_step_status.pl -host ${host} -user ${user} -pass ${pass} -port ${port} -dbname ${dbname} -output ${output} -ftp_dir ${ftp_dir} ${website} ${private}

# Copy to the website
#if [[ ${copy_output_file} == 1 ]]; then
#  bash ${perldir}/shell/copy_files_to_website.sh ${output} curation-status index.html
#fi

