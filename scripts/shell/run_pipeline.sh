#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

perldir=${CVSROOTDIR}/lrg-code/scripts

#e.g. ./run_pipeline.sh LRG_5 LEPRE1 GRCh37 xml_test new_xml xml_dir xml_dir/pipeline_reports.txt

lrg_id=$1
hgnc=$2
assembly=$3
xml_dir=$4
new_dir=$5
tmp_dir=$6
skip_hc=$7
annotation_test=${8}

if [ -z ${tmp_dir} ] ; then
  tmp_dir='.'
fi

if [[ -z ${annotation_test} ]] ; then
  annotation_test=0
fi

skip_hc_options="fixed mapping polya main" # all: all of these options

report_file=${tmp_dir}/pipeline_reports.txt
error_log=${tmp_dir}/error_log_${lrg_id}.txt
warning_log=${tmp_dir}/warning_log_${lrg_id}.txt
warning='none'

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
  if [[ -s ${warning_log} ]] ; then
    echo_stderr  "WARNING: at least one NCBI transcript has a polyA!"
    echo_stderr  "Please, look at the warning log file ${warning_log} for more details"
    warning='polyA'
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
    
    if [[ ${skip_hc} =~ 'fixed' ]] ; then
      comment="${comment} - Fixed section checks skipped for this LRG"
    fi
    if [[ ${skip_hc} =~ 'mapping' ]] ; then
      comment="${comment} - Global mapping checks skipped for this LRG"
    fi
    if [[ ${skip_hc} =~ 'polya' ]] ; then
      comment="${comment} - PolyA comparison skipped for this LRG"
    fi
    if [[ ${skip_hc} =~ 'main' ]] ; then
      comment="${comment} - Main HealthChecks skipped for this LRG"
    fi
    if [[ ${warning} == 'polyA' ]] ; then
      comment="${comment} - WARNING: at least one of the NCBI transcripts has a polyA sequence"
    fi
    if [[ ! ${skip_hc} =~ 'main' ]] ; then
      is_partial=`perl ${perldir}/pipeline/check.lrg.pl -xml_file ${xmlfile} -check partial_gene`
      if [[ -n ${is_partial} ]] ; then
        comment="${comment} - Partial gene/transcript/protein found"
        echo "failed${comment}" >> ${report_file}
        return 1
      fi
    fi  
    
    echo "ran successfully${comment}" >> ${report_file}
  fi
}


#### PIPELINE #########################################################################################################
comment="#=="
for i in $(seq 1 ${#lrg_id})
do
 comment="$comment="
done
comment="$comment==#"
echo_stderr  $comment >&2
echo_stderr  "#|  ${lrg_id}  |#" >&2
echo_stderr  $comment >&2


# Check the correct terms for HealthChecks skip options
if [[ ${skip_hc} ]] ; then
  skip_hc=`echo $skip_hc | tr -d [[:space:]]`
  
  if [[ -n ${skip_hc} && ${skip_hc} != 0 ]] ; then
    if [[ ${skip_hc} = 'all' ]] ; then
      skip_hc=$skip_hc_options
    fi
    
    listOfSkipHc=`echo $skip_hc | sed -e 's/,/ /g'`
    
    for i in $listOfSkipHc
    do
      found=`echo $skip_hc_options | grep $i`
      if [[ -z ${found} ]] ; then
        echo_stderr "ERROR: the HealthCheck skip option '$i' is not recognized!"
        echo_stderr "The script is ended for this LRG."
        if [ -n "${report_file}" ] ; then
          echo "failed (wrong HealthChecks skip option used)" >> ${report_file}
        fi
        exit 1
      fi
    done
  fi
fi


# Preliminary test: compare fixed section with existing LRG entry
if [[ ! ${skip_hc} =~ 'fixed' ]] ; then
  echo_stderr  "# Preliminary check: compare fixed section with existing LRG entry ... " >&2
  rm -f ${error_log}
  bash ${perldir}/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml ${assembly} unknown "-check existing_entry" 2> ${error_log}
  check_script_result
  echo_stderr  "> checking comparison done" 
  echo_stderr  ""
fi

# Test the mapping: compare global mapping with existing LRG entry
if [[ ! ${skip_hc} =~ 'mapping' ]] ; then
  echo_stderr  "# Mapping check: compare global mapping with existing LRG entry ... " >&2
  rm -f ${error_log}
  bash ${perldir}/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml ${assembly} unknown "-check compare_main_mapping" 2> ${error_log}
  check_script_result
  echo_stderr  "> checking comparison done" 
  echo_stderr  ""
fi


# Test PolyA sequence
if [[ ! ${skip_hc} =~ 'polya' ]] ; then
  echo_stderr  "# PolyA check: compare LRG genomic sequence with RefSeqGene (checks if there is a polyA) ... " >&2
  rm -f ${error_log}
  rm -f ${warning_log}
  bash ${perldir}/shell/compare_sequence_tail.sh ${xml_dir}/${lrg_id}.xml ${annotation_test} ${error_log}
  check_script_result
  check_script_warning
  echo_stderr  "> checking polyA done" 
  echo_stderr  ""
fi


# STEP1: HealthCheck 1 - check raw data
if [[ ! ${skip_hc} =~ 'main' ]] ; then
  echo_stderr  "# Check data file #1 ... " >&2
  rm -f ${error_log}
  bash ${perldir}/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml ${assembly} unknown 2> ${error_log}
  check_script_result
  echo_stderr  "> checking #1 done" 
  echo_stderr  ""
fi


# STEP2: Add Ensembl annotations
echo_stderr  "# Add annotations ... "
bash ${perldir}/shell/update_xml_annotation.sh ${xml_dir}/${lrg_id}.xml ${hgnc} ${assembly}
check_empty_file ${xml_dir}/${lrg_id}.xml.new "Annotations done"


# STEP3: HealthCheck 2 - check annotation data
if [[ ! ${skip_hc} =~ 'main' ]] ; then
  echo_stderr  "# Check data file #2 ... "
  rm -f ${error_log}
  bash ${perldir}/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml.new ${assembly} unknown 2> ${error_log}
  check_script_result
  echo_stderr  "> checking #2 done"
  echo_stderr  ""
fi


# End the script if in test mode (only want to test the Ensembl annotations)
if [[ ${annotation_test} == 2 ]] ; then
  end_of_script ${xml_dir}/${lrg_id}.xml.new
  echo_stderr "TEST done."
  exit 0
fi


# STEP4: Store the XML data into the LRG database
echo_stderr  "# Store ${lrg_id} into the database ... "
bash ${perldir}/shell/import_into_db.sh ${xml_dir}/${lrg_id}.xml.new ${hgnc} ${annotation_test} ${error_log} ${warning}
check_script_result
echo_stderr  "> Storage done"
echo_stderr  ""


# STEP5: Export the LRG data from the database to an XML file (new requester/lsdb/contact data)
echo_stderr  "# Extract ${lrg_id} from the database ... "
bash ${perldir}/shell/export_from_db.sh ${lrg_id} ${xml_dir}/${lrg_id}.xml.exp ${annotation_test}
check_empty_file ${xml_dir}/${lrg_id}.xml.exp "Extracting done"


# STEP6: HealthCheck 3 - check the exported data
if [[ ! ${skip_hc} =~ 'main' ]] ; then
  echo_stderr  "# Check data file #3 ... "
  rm -f ${error_log}
  bash ${perldir}/shell/healthcheck_record.sh ${xml_dir}/${lrg_id}.xml.exp ${assembly} unknown 2> ${error_log}
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
perl ${perldir}/pipeline/lrg2fasta.pl -xml_dir ${new_dir} -fasta_dir ${new_dir}/fasta -xml_file ${lrg_id}.xml
check_empty_file ${new_dir}/fasta/${lrg_id}.fasta "Fasta file created"



echo_stderr  "# Create GFF files ... "
assembly_37='GRCh37'
assembly_38='GRCh38'
echo_stderr  "> Create GFF file in ${assembly_37} ... "
perl ${perldir}/pipeline/lrg2gff.pl -lrg ${lrg_id} -out ${new_dir}/gff/${lrg_id}_${assembly_37}.gff -xml ${new_dir}/${lrg_id}.xml -assembly ${assembly_37}
check_empty_file ${new_dir}/gff/${lrg_id}_${assembly_37}.gff "GFF file for ${assembly_37} created"

echo_stderr  "> Create GFF file in ${assembly_38} ... "
perl ${perldir}/pipeline/lrg2gff.pl -lrg ${lrg_id} -out ${new_dir}/gff/${lrg_id}_${assembly_38}.gff -xml ${new_dir}/${lrg_id}.xml -assembly ${assembly_38}
check_empty_file ${new_dir}/gff/${lrg_id}_${assembly_38}.gff "GFF file for ${assembly_38} created"



end_of_script ${new_dir}/${lrg_id}.xml

echo_stderr  "Script done"
echo_stderr  ""
echo_stderr  ""
