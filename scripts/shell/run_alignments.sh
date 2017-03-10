#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths


xml_dirs=$1
output_dir=$2
genes_input_file=$3

perldir=${LRGROOTDIR}/lrg-code/scripts/align

genes_file_option=''

if [ -d ${output_dir} ] && [ ${output_dir} != "" ] ; then
  rm -f ${output_dir}/*.html
fi
if [[ -z ${genes_file} ]]; then
  genes_file_option=" -genes_list_file ${genes_input_file}"
fi

perl ${perldir}/generate_transcript_alignments.pl -xml_dirs ${xml_dirs} -output_dir ${output_dir}${genes_file_option}
