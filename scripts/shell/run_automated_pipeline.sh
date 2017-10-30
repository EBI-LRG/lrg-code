#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

perldir=${LRGROOTDIR}/lrg-code/scripts

#e.g. ./run_pipeline.sh LRG_5 LEPRE1 GRCh37 xml_test new_xml xml_dir xml_dir/pipeline_reports.txt

lrg_id=$1
hgnc=$2
assembly=$3
status=$4
xml_dir=$5
xml_file=$6
new_dir=$7
tmp_dir=$8
report_file=$9
skip_hc=${10}
skip_extra_hc=${11}
annotation_test=${12}

if [ -z ${tmp_dir} ] ; then
  tmp_dir='.'
fi

if [[ -z ${annotation_test} ]] ; then
  annotation_test=0
fi

if [[ -z ${skip_extra_hc} ]] ; then
  skip_extra_hc=0
fi

skip_hc_options="fixed mapping polya main" # all: all of these options

log_file=${tmp_dir}/log/log_${lrg_id}.txt
error_log=${tmp_dir}/error/error_log_${lrg_id}.txt
warning_log=${tmp_dir}/warning/warning_log_${lrg_id}.txt
warning='none'
fixed_section_diff='no'

#### METHODS ##########################################################################

function check_script_result {
  if [[ -s ${error_log} ]] ; then
    echo_log  "ERROR: the script failed!"
    echo_log  "Please, look at the error log file ${error_log} for more details"
    if [ -n "${report_file}" ] ; then
      echo -e "${lrg_id}\tfailed\t\t" >> ${report_file}
    fi
    echo_stderr "Failed!"
    # Copy failed LRG XML file to the 'failed' directory 
    cp ${xml_dir}/${xml_file} ${new_dir}/failed/${xml_file}
    exit 1 #exit shell script
  fi
}

function check_script_warning {
  type=$1
  if [[ -s ${warning_log} ]] ; then
    if [[ ${type} = 'polyA' ]] ; then
      echo_log  "WARNING: at least one NCBI transcript has a polyA!"
    elif [[ ${type} = 'fixed' ]] ; then
      echo_log  "WARNING: the fixed section of the LRG is different from the EBI FTP site!"
    fi
    echo_log  "Please, look at the warning log file ${warning_log} for more details"
    if [[ ${warning} = 'none' ]] ; then
      warning=${type}
    else
      warning="${warning},${type}"
    fi
  fi
}

function check_empty_file {
  file_path=$1
  msg=$2
  if [[ -s ${file_path} ]] ; then
    echo_log  "> ${msg}"
    echo_log  ""
  else  
    echo_log  "ERROR: the script failed!"
    if [ -n "${report_file}" ] ; then
      echo -e "${lrg_id}\tfailed\t\t" >> ${report_file}
    fi
    echo_stderr "Failed!"
    exit 1 #exit shell script
  fi
}

function echo_log {
  msg=$1
  echo ${msg} >> ${log_file}
}

function echo_stderr {
  msg=$1
  echo ${msg} >&2
}

function end_of_script {
  file_path=$1
  not_successful=$2
  comment=''
  comment_warning=''
  if [ -n "${report_file}" ] ; then
    
    if [[ ${skip_hc} =~ 'fixed' ]] ; then
      comment="${comment}Fixed section checks skipped for this LRG;"
    fi
    if [[ ${skip_hc} =~ 'mapping' ]] ; then
      comment="${comment}Global mapping checks skipped for this LRG;"
    fi
    if [[ ${skip_hc} =~ 'polya' ]] ; then
      comment="${comment}PolyA comparison skipped for this LRG;"
    fi
    if [[ ${skip_hc} =~ 'main' ]] ; then
      comment="${comment}Main HealthChecks skipped for this LRG;"
    fi
    # Warnings
    if [[ ${warning} =~ 'polyA' ]] ; then
      comment_warning="${comment_warning}At least one of the NCBI transcripts has a polyA sequence;"
    fi
    if [[ ${warning} =~ 'fixed' ]] ; then
      comment_warning="${comment_warning}The fixed section of the LRG is different from the EBI FTP site;"
    fi
    if [[ ! ${skip_hc} =~ 'main' ]] ; then
      is_partial=`perl ${perldir}/pipeline/check.lrg.pl -xml_file ${file_path} -check partial_gene`
      if [[ -n ${is_partial} && ${status} != 'public' ]] ; then
        comment="${comment}Partial gene/transcript/protein found;"
        echo -e "${lrg_id}\tfailed\t${comment}\t${comment_warning}" >> ${report_file}
        return 1
      fi
    fi  
    
    # Failed pipeline
    if [[ ${not_successful} == 1 ]] ; then
      echo -e "${lrg_id}\tstopped\t${comment}\t${comment_warning}" >> ${report_file}
      echo_stderr "Stopped!"
    # New LRG records - success pipeline
    elif [[ ${status} == 'new' ]] ; then
      echo -e "${lrg_id}\twaiting\t${comment}\t${comment_warning}" >> ${report_file}
      echo_stderr "New LRG record - Waiting to manually check and copy the XML file to the FTP site!"
    # Fixed section changed - pending or stalled LRG records
    elif [[ ${status} != 'public' && ${fixed_section_diff} == 1 ]] ; then
      echo -e "${lrg_id}\twaiting\t${comment}\t${comment_warning}" >> ${report_file}
      echo_stderr "Fixed section has changed - Waiting to manually check and copy the XML file to the FTP site!"
    # Success pipeline
    else
      echo -e "${lrg_id}\tsucceed\t${comment}\t${comment_warning}" >> ${report_file}
      echo_stderr "Succeed!"
    fi
  fi
}

function move_file_to_directory {
  xmlfile=$1
  err_log_file=$2
  # Do not import public LRG with different fixed annotations
  if [[ ${status} == 'public' && ${fixed_section_diff} == 1 ]] ; then
    cp ${xmlfile} "${new_dir}/failed/${xml_file}"
    if [ -n "${report_file}" ] ; then
      echo -e "${lrg_id}\tfailed\t\t" >> ${report_file}
    fi
    echo -e "ERROR: the fixed section of this LRG is different from the LRG XML file on the public FTP site" >> ${err_log_file}
    echo_stderr "Failed!"
    exit 1 #exit shell script
  fi
}


#### PIPELINE #########################################################################################################
comment="#=="
for i in $(seq 1 ${#lrg_id})
do
 comment="$comment="
done
comment="$comment==#"
echo_stderr ""
echo_stderr  $comment
echo_stderr  "#|  ${lrg_id}  |#"
echo_stderr  $comment

echo_log "# ${lrg_id}"

skip_checks='requester'

if [[ ${skip_extra_hc} && ${skip_extra_hc} != 0 ]]; then
  echo_log "HealthChecks skipped: ${skip_extra_hc}"
  skip_checks="requester ${skip_extra_hc}"
fi


rm -f ${warning_log}

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
        echo_log "ERROR: the HealthCheck skip option '$i' is not recognized!"
        echo_log "The script is ended for this LRG."
        echo_stderr "Failed!"
        if [ -n "${report_file}" ] ; then
          echo -e "${lrg_id}\tfailed\t(wrong HealthChecks skip option used)" >> ${report_file}
        fi
        exit 1
      fi
    done
  fi
fi


# Preliminary test: compare fixed section with existing LRG entry
if [[ ! ${skip_hc} =~ 'fixed' ]] ; then
  echo_log  "# Preliminary check: compare fixed section with existing LRG entry ... "
  if [[ ${status} == 'public' || ${status} == 'pending' ]] ; then
    bash ${perldir}/shell/healthcheck_record.sh ${xml_dir}/${xml_file} ${assembly} ${status} "-check existing_entry" 2> ${warning_log}
    check_script_warning 'fixed'
    if [[ -s ${warning_log} ]] ; then
      fixed_section_diff=1
    fi
  else
    rm -f ${error_log}
    bash ${perldir}/shell/healthcheck_record.sh ${xml_dir}/${xml_file} ${assembly} ${status} "-check existing_entry" 2> ${error_log}
    check_script_result
  fi
  echo_log  "> checking comparison done" 
  echo_log  ""
fi

# Test the mapping: compare global mapping with existing LRG entry
if [[ ! ${skip_hc} =~ 'mapping' ]] && [[ ${skip_extra_hc} != 'compare_main_mapping' ]]; then
  echo_log  "# Mapping check: compare global mapping with existing LRG entry ... "
  rm -f ${error_log}
  bash ${perldir}/shell/healthcheck_record.sh ${xml_dir}/${xml_file} ${assembly} ${status} "-check compare_main_mapping" 2> ${error_log}
  check_script_result
  echo_log  "> checking comparison done" 
  echo_log  ""
fi


# Test PolyA sequence
if [[ ! ${skip_hc} =~ 'polya' ]] ; then
  echo_log  "# PolyA check: compare LRG genomic sequence with RefSeqGene (checks if there is a polyA) ... "
  rm -f ${error_log}
  bash ${perldir}/shell/compare_sequence_tail.sh ${xml_dir}/${xml_file} ${annotation_test} ${error_log} ${warning_log}
  check_script_result
  check_script_warning 'polyA'
  echo_log  "> checking polyA done" 
  echo_log  ""
fi


## STEP 1: HealthCheck 1 - check raw data
if [[ ! ${skip_hc} =~ 'main' ]] ; then
  echo_log  "# Check data file #1 ... " >&2
  rm -f ${error_log}
  bash ${perldir}/shell/healthcheck_record.sh ${xml_dir}/${xml_file} ${assembly} ${status} "-skip_check ${skip_checks}" 2> ${error_log}
  check_script_result
  echo_log  "> checking #1 done" 
  echo_log  ""
fi


## STEP 2: Add Ensembl annotations
echo_log  "# Add annotations ... "
bash ${perldir}/shell/update_xml_annotation.sh ${xml_dir}/${xml_file} ${hgnc} ${assembly} >> ${log_file} 2>&1
check_empty_file ${xml_dir}/${xml_file}.new "Annotations done"


## STEP 3: HealthCheck 2 - check annotation data
if [[ ! ${skip_hc} =~ 'main' ]] ; then
  echo_log  "# Check data file #2 ... "
  rm -f ${error_log}
  bash ${perldir}/shell/healthcheck_record.sh ${xml_dir}/${xml_file}.new ${assembly} ${status} "-skip_check ${skip_checks}" 2> ${error_log}
  check_script_result
  echo_log  "> checking #2 done"
  echo_log  ""
fi


# End the script if in test mode (only want to test the Ensembl annotations)
if [[ ${annotation_test} == 2 ]] ; then
  end_of_script ${xml_dir}/${xml_file}.new
  echo_log "TEST done."
  exit 0
fi


# Public LRG with different fixed annotations: store the file in a separate directory
# before the step of storing the XML data in the LRG database
if [[ ${status} == 'public' && ${fixed_section_diff} == 1 && ! ${skip_hc} =~ 'fixed' ]] ; then
  move_file_to_directory ${xml_dir}/${xml_file}.new ${error_log}
fi

## STEP 4: Store the XML data into the LRG database
echo_log  "# Store ${lrg_id} into the database ... "
if [[ ${status} == 'public' ]] ; then
  echo_log  "> Only store the updatable annotations for this LRG"
  bash ${perldir}/shell/import_upd_into_db.sh ${xml_dir}/${xml_file}.new ${hgnc} ${annotation_test} ${error_log} ${warning}
else
  bash ${perldir}/shell/import_all_into_db.sh ${xml_dir}/${xml_file}.new ${hgnc} ${annotation_test} ${error_log} ${warning}
fi
check_script_result
echo_log  "> Storage done"
echo_log  ""


## STEP 5: Export the LRG data from the database to an XML file (new requester/lsdb/contact data)
echo_log  "# Extract ${lrg_id} from the database ... "
bash ${perldir}/shell/export_from_db.sh ${lrg_id} ${xml_dir}/${xml_file}.exp ${annotation_test}
check_empty_file ${xml_dir}/${xml_file}.exp "Extracting done"


## STEP 6: HealthCheck 3 - check the exported data
if [[ ! ${skip_hc} =~ 'main' ]] ; then
  echo_log  "# Check data file #3 ... "
  rm -f ${error_log}
  bash ${perldir}/shell/healthcheck_record.sh ${xml_dir}/${xml_file}.exp ${assembly} ${status} "-skip_check ${skip_extra_hc}" 2> ${error_log}
  check_script_result
  echo_log  "> checking #3 done"
  echo_log  ""
fi


## STEP 7: Move the exported file into temporary directory and generate FASTA and GFF files
echo_log  "Move XML file to ${new_dir}"
rm -f ${error_log}
lrg_xml_exp=${xml_dir}/${xml_file}.exp
lrg_xml_dir=${new_dir}
# Public LRG
if [[ ${status} == 'public' ]] ; then
  lrg_xml_dir="${new_dir}/public"
# Pending
elif [[ ${status} == 'pending' ]] ; then
  if [[ ${fixed_section_diff} == 1 ]] ; then
    lrg_xml_dir="${new_dir}/temp/pending"
  else
    lrg_xml_dir="${new_dir}/pending"
  fi
# Stalled
elif [[ ${status} == 'stalled' ]] ; then
  if [[ ${fixed_section_diff} == 1 ]] ; then
    lrg_xml_dir="${new_dir}/temp/stalled"
  else
    lrg_xml_dir="${new_dir}/stalled"
  fi
# New
elif [[ ${status} == 'new' ]] ; then
  lrg_xml_dir="${new_dir}/temp/new"
fi
# Move file to the correct temporary repository
mv ${lrg_xml_exp} ${lrg_xml_dir}/${xml_file} 2> ${error_log}
check_script_result
echo_log  "> Move done"
echo_log  ""


echo_log  "# Create Fasta file ... "
perl ${perldir}/pipeline/lrg2fasta.pl -xml_dir ${lrg_xml_dir} -fasta_dir ${new_dir}/fasta -xml_file ${lrg_id}.xml
check_empty_file ${new_dir}/fasta/${lrg_id}.fasta "Fasta file created"



echo_log  "# Create GFF files ... "
assembly_37='GRCh37'
assembly_38='GRCh38'
echo_log  "> Create GFF file in ${assembly_37} ... "
perl ${perldir}/pipeline/lrg2gff.pl -lrg ${lrg_id} -out ${new_dir}/gff/${lrg_id}_${assembly_37}.gff -xml ${lrg_xml_dir}/${xml_file} -assembly ${assembly_37}
check_empty_file ${new_dir}/gff/${lrg_id}_${assembly_37}.gff "GFF file for ${assembly_37} created"

echo_log  "> Create GFF file in ${assembly_38} ... "
perl ${perldir}/pipeline/lrg2gff.pl -lrg ${lrg_id} -out ${new_dir}/gff/${lrg_id}_${assembly_38}.gff -xml ${lrg_xml_dir}/${xml_file} -assembly ${assembly_38}
check_empty_file ${new_dir}/gff/${lrg_id}_${assembly_38}.gff "GFF file for ${assembly_38} created"

end_of_script ${lrg_xml_dir}/${xml_file}

echo_log  "Script done"
echo_log  ""
