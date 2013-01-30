#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

#e.g. ./run_pipeline.sh LRG_5 LEPRE1 GRCh37 xml_test new_xml xml_dir xml_dir/pipeline_reports.txt

lrg_id=$1
hgnc=$2
assembly=$3
xml_dir=$4
new_dir=$5
tmp_dir=$6
report_file=$7
skip_hc=$8
skip_check0=$9

if [ -z ${tmp_dir} ] ; then
	tmp_dir='.'
fi

if [[ ! ${skip_hc} ]] ; then
  skip_hc=0
fi

error_log=${tmp_dir}/error_log_${lrg_id}.txt

function check_script_result {
	if [[ -s ${error_log} ]] ; then
		echo_stderr  "ERROR: the script failed!"
		echo_stderr  "Please, look at the error log file ${error_log} for more details"
		if [ -n "${report_file}" ] ; then
			echo  "failed" >> ${report_file}
		fi
		exit 1 #exit shell script
	fi
}

function check_empty_file {
	file_path=$1
	msg=$2
	if [[ -s ${file_path} ]] ; then
		echo_stderr  "> ${msg}"
		echo_stderr  ""
	else	
		echo_stderr  "ERROR: the script failed!"
		if [ -n "${report_file}" ] ; then
			echo "failed" >> ${report_file}
		fi
		exit 1 #exit shell script
	fi
}

function echo_stderr {
	msg=$1
	echo ${msg} >&2
}

echo_stderr  "#### ${lrg_id} ####" >&2

if [ ! ${skip_check0} ] ; then
  echo_stderr  "# Preliminary check: compare with existing LRG entry ... " >&2
  rm -f ${error_log}
  bash code/scripts/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml "-check existing_entry" 2> ${error_log}
  check_script_result
  echo_stderr  "> checking comparison done" 
  echo_stderr  ""
fi

if [ ${skip_hc} == 0 ] ; then
  echo_stderr  "# Check data file #1 ... " >&2
  rm -f ${error_log}
  bash code/scripts/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml 2> ${error_log}
  check_script_result
  echo_stderr  "> checking #1 done" 
  echo_stderr  ""
fi


echo_stderr  "# Add annotations ... "
bash code/scripts/shell/update_xml_annotation.sh ${xml_dir}/${lrg_id}.xml ${hgnc} ${assembly}
check_empty_file ${xml_dir}/${lrg_id}.xml.new "Annotations done"


if [ ${skip_hc} == 0 ] ; then
  echo_stderr  "# Check data file #2 ... "
  rm -f ${error_log}
  bash code/scripts/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml.new 2> ${error_log}
  check_script_result
  echo_stderr  "> checking #2 done"
  echo_stderr  ""
fi


echo_stderr  "# Store ${lrg_id} into the database ... "
bash code/scripts/shell/import_into_db.sh ${xml_dir}/${lrg_id}.xml.new 7Ntoz3HH ${hgnc} ${error_log}
check_script_result
echo_stderr  "> Storage done"
echo_stderr  ""


echo_stderr  "# Extract ${lrg_id} from the database ... "
bash code/scripts/shell/export_from_db.sh ${lrg_id} ${xml_dir}/${lrg_id}.xml.exp
check_empty_file ${xml_dir}/${lrg_id}.xml.exp "Extracting done"


if [ ${skip_hc} == 0 ] ; then
  echo_stderr  "# Check data file #3 ... "
  rm -f ${error_log}
  bash code/scripts/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml.exp 2> ${error_log}
  check_script_result
  echo_stderr  "> checking #3 done"
  echo_stderr  ""
fi


echo_stderr  "Move XML file to ${new_dir}"
rm -f ${error_log}
mv ${xml_dir}/${lrg_id}.xml.exp ${new_dir}/${lrg_id}.xml 2> ${error_log}
check_script_result
echo_stderr  "> Move done"
echo_stderr  ""


echo_stderr  "# Create Fasta file ... "
perl code/scripts/lrg2fasta.pl -xml_dir ${new_dir} -fasta_dir ${new_dir}/fasta -xml_file ${lrg_id}.xml
check_empty_file ${new_dir}/fasta/${lrg_id}.fasta "Fasta file created"


echo_stderr  "# Create GFF file ... "
perl code/scripts/lrg2gff.pl -lrg ${lrg_id} -out ${new_dir}/gff/${lrg_id}.xml.gff -xml ${new_dir}/${lrg_id}.xml -assembly ${assembly}
check_empty_file ${new_dir}/gff/${lrg_id}.xml.gff "GFF file created"

echo_stderr  "Script done"
echo_stderr  ""
echo_stderr  ""

if [ -n "${report_file}" ] ; then
  is_partial=`perl code/scripts/check.lrg.pl -xml_file ${new_dir}/${lrg_id}.xml -check partial_gene`
 
  if [[ -n ${is_partial} ]] ; then
    echo "ran successfully - Partial gene/transcript/protein found!" >> ${report_file}
  elif [[ ${skip_hc} == 1 ]] ; then
    echo "ran successfully - HealthChecks skipped for this LRG!" >> ${report_file}
  else
   echo "ran successfully" >> ${report_file}
  fi 
fi
