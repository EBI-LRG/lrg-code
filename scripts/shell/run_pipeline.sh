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
annotation_test=${10}

if [ -z ${tmp_dir} ] ; then
	tmp_dir='.'
fi

if [[ ! ${skip_hc} ]] ; then
  skip_hc=0
fi

error_log=${tmp_dir}/error_log_${lrg_id}.txt
warning=''

#### METHODS ##########################################################################

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

function check_script_warning {
	if [[ -s ${error_log} ]] ; then
		echo_stderr  "WARNING: at least one NCBI transcript has a polyA!"
		echo_stderr  "Please, look at the error log file ${error_log} for more details"
		warning=1
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

function end_of_script {
  xmlfile=$1
  comment=''
  if [ -n "${report_file}" ] ; then
    is_partial=`perl code/scripts/check.lrg.pl -xml_file ${xmlfile} -check partial_gene`
    
    if [[ ${skip_hc} == 1 ]] ; then
      comment="${comment} - HealthChecks skipped for this LRG"
    elif [[ ${warning} == 1 ]] ; then
      comment="${comment} - WARNING: at least one NCBI transcript has a polyA sequence"
    elif [[ -n ${is_partial} ]] ; then
      comment="${comment} - Partial gene/transcript/protein found"
    fi
    echo "ran successfully${comment}" >> ${report_file}
  fi
}


#### PIPELINE #########################################################################################################

echo_stderr  "#### ${lrg_id} ####" >&2

# Preliminary test
if [[ ! ${skip_check0} || ${skip_check0} == 0 ]] ; then
  echo_stderr  "# Preliminary check: compare sequences with existing LRG entry ... " >&2
  rm -f ${error_log}
  bash code/scripts/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml "-check existing_entry" 2> ${error_log}
  check_script_result
  echo_stderr  "> checking comparison done" 
  echo_stderr  ""
fi


# Test PolyA sequence
if [ ${skip_hc} == 0 ] ; then 
  echo_stderr  "# PolyA check: compare LRG genomic sequence with RefSeqGene (checks if there is a polyA) ... " >&2
  rm -f ${error_log}
  bash code/scripts/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml "-check poly_a" 2> ${error_log}
  check_script_warning
  echo_stderr  "> checking polyA done" 
  echo_stderr  ""
fi


# STEP1: HealthCheck 1 - check raw data
if [ ${skip_hc} == 0 ] ; then
  echo_stderr  "# Check data file #1 ... " >&2
  rm -f ${error_log}
  bash code/scripts/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml 2> ${error_log}
  check_script_result
  echo_stderr  "> checking #1 done" 
  echo_stderr  ""
fi


# STEP2: Add Ensembl annotations
echo_stderr  "# Add annotations ... "
bash code/scripts/shell/update_xml_annotation.sh ${xml_dir}/${lrg_id}.xml ${hgnc} ${assembly}
check_empty_file ${xml_dir}/${lrg_id}.xml.new "Annotations done"


# STEP3: HealthCheck 2 - check annotation data
if [ ${skip_hc} == 0 ] ; then
  echo_stderr  "# Check data file #2 ... "
  rm -f ${error_log}
  bash code/scripts/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml.new 2> ${error_log}
  check_script_result
  echo_stderr  "> checking #2 done"
  echo_stderr  ""
fi


# End the script if in test mode (only want to test the Ensembl annotations)
if [[ ${annotation_test} == 1 ]] ; then
	end_of_script ${xml_dir}/${lrg_id}.xml.new
	echo_stderr "TEST done."
  exit 0
fi


# STEP4: Store the XML data into the LRG database
echo_stderr  "# Store ${lrg_id} into the database ... "
bash code/scripts/shell/import_into_db.sh ${xml_dir}/${lrg_id}.xml.new 7Ntoz3HH ${hgnc} ${error_log}
check_script_result
echo_stderr  "> Storage done"
echo_stderr  ""


# STEP5: Export the LRG data from the database to an XML file (new requester/lsdb/contact data)
echo_stderr  "# Extract ${lrg_id} from the database ... "
bash code/scripts/shell/export_from_db.sh ${lrg_id} ${xml_dir}/${lrg_id}.xml.exp
check_empty_file ${xml_dir}/${lrg_id}.xml.exp "Extracting done"


# STEP6: HealthCheck 3 - check the exported data
if [ ${skip_hc} == 0 ] ; then
  echo_stderr  "# Check data file #3 ... "
  rm -f ${error_log}
  bash code/scripts/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml.exp 2> ${error_log}
  check_script_result
  echo_stderr  "> checking #3 done"
  echo_stderr  ""
fi


# STEP7: Move the exported file and generate FASTA and GFF files
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

end_of_script ${new_dir}/${lrg_id}.xml
