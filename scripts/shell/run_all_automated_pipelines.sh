#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

pubpath=${PUBFTP}

xml_dir=$1
new_dir=$2
tmp_dir=$3
is_test_hc=$4      # Test the Ensembl annotations

xml_dir_sub='xml'
reports_file='pipeline_reports.txt'

if [[ -n ${is_test_hc} && ${is_test_hc} != 0 ]] ; then
  if [[ ${is_test_hc} == 'is_hc' ]]; then
    is_test_hc='-is_hc'
  else
    is_test_hc='-is_test'
  fi
else
  is_test_hc=''
fi

perldir=${CVSROOTDIR}/lrg-code/scripts/auto_pipeline

# Extract the XML files 
#perl ${perldir}/get_data_files.pl -xml_tmp_dir ${xml_dir}

# Run the pipeline for each LRG XML file
perl ${perldir}/pipeline_dispatcher.pl -ncbi_xml_dir ${xml_dir}/${xml_dir_sub} -new_xml_dir ${new_dir} -reports_dir ${tmp_dir} -reports_file ${reports_file} ${is_test_hc}

# Generate an HTML output of the pipeline reports
perl ${perldir}/reports2html.pl -reports_dir ${tmp_dir} -reports_file ${reports_file} -xml_dir ${new_dir} -ftp_dir ${pubpath}

# Update xml CVS directory with the updated LRG XML files. 

# Generate index files

# Copy LRG XML, fasta, gff and index XML files to the LRG FTP

# Run the script updates_relnotes_file.sh





