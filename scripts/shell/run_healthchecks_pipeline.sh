#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

#e.g. ./run_healthchecks_pipeline.sh LRG_5 LEPRE1 GRCh37 xml_test tmp_dir

lrg_id=$1
hgnc=$2
assembly=$3
xml_dir=$4
tmp_dir=$5


report_file=${tmp_dir}/pipeline_reports.txt
error_log=${tmp_dir}/error_log_${lrg_id}.txt
tmp_error_log=${tmp_dir}/tmp_error_log_${lrg_id}.txt
warning_log=${tmp_dir}/warning_log_${lrg_id}.txt
tmp_warning_log=${tmp_dir}/tmp_warning_log_${lrg_id}.txt
warning='none'

#### METHODS ##########################################################################

function check_script_result {
  script_msg=$1
	if [[ -s ${tmp_error_log} ]] ; then
		echo_stderr  " ${script_msg}!"
		echo_stderr  "\t> ERROR: Please, look at the error log file ${error_log} for more details" '-e'
		cat ${tmp_error_log} >> ${error_log}
	else
	  echo_stderr " seems OK!"
	fi
}


function check_script_warning {
	if [[ -s ${tmp_warning_log} ]] ; then
	  mv ${tmp_warning_log} ${warning_log}
		echo_stderr  "At least one NCBI transcript has a polyA!"
		echo_stderr  "\t> WARNING: Please, look at the warning log file ${warning_log} for more details" '-e'
		warning='polyA'
	else
		echo_stderr " seems OK!"
	fi
}


function echo_stderr {
	msg=$1
  option=$2
	echo ${option} ${msg} >&2
}

function end_of_script {
  xmlfile=$1
  comment=''
  if [[ -s "${report_file}" ]] ; then
    
    if [[ ${warning} == 'polyA' ]] ; then
      comment="${comment} - WARNING: at least one of the NCBI transcripts has a polyA sequence"
    fi 
    
    if [[ -s "${error_log}" ]] ; then
      echo "failed${comment}" >> ${report_file}
    else
      echo "ran successfully${comment}" >> ${report_file}
    fi 
  fi
}


#### PIPELINE #########################################################################################################
comment="#=============="
for i in $(seq 1 ${#lrg_id})
do
 comment="$comment="
done
comment="$comment==#"
echo_stderr  $comment >&2
echo_stderr  "#|  ${lrg_id} - TEST MODE  |#" >&2
echo_stderr  $comment >&2

rm -f ${error_log}


# Compare fixed section with existing LRG
echo_stderr  '1) FIXED SECTION: Compare fixed section with existing LRG entry ... ' '-n'
rm -f ${tmp_error_log}
bash lrg-code/scripts/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml ${assembly} "-check existing_entry" 2> ${tmp_error_log}
check_script_result 'The new fixed section is different'


# Preliminary test
echo_stderr  "2) MAPPING: Compare global mapping with archived LRG entry ... " '-n'
rm -f ${tmp_error_log}
bash lrg-code/scripts/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml ${assembly} "-check compare_main_mapping" 2> ${tmp_error_log}
check_script_result 'The new global mapping is different'


# Test PolyA sequence
echo_stderr  '3) POLY A: Compare LRG genomic sequence with RefSeqGene (checks if there is a polyA) ... ' '-n' 
rm -f ${tmp_error_log}
rm -f ${warning_log}
bash lrg-code/scripts/shell/compare_sequence_tail.sh ${xml_dir}/${lrg_id}.xml ${tmp_error_log} 1
#check_script_result 'ERROR while comparing the tail of the LRG sequence with the RefSeqGene tail sequence'
check_script_warning


# HealthChecks
echo_stderr  '4) HEALTHCHECKS: Run full HealthChecks ... ' '-n' 
rm -f ${tmp_error_log}
bash lrg-code/scripts/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml ${assembly} 2> ${tmp_error_log}
check_script_result 'The main healthchecks returned at least one error'


echo_stderr  "Tests done"
echo_stderr  ""
echo_stderr  ""

rm -f ${tmp_error_log}

end_of_script ${new_dir}/${lrg_id}.xml
