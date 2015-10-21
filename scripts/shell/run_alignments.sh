#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths


xml_dirs=$1
output_dir=$2

perldir=${CVSROOTDIR}/lrg-code/scripts/align

if [ -d "${output_dir}" && ${output_dir} != "" ] ; then
  rm -f "${output_dir}/*.html"
fi

perl ${perldir}/generate_transcript_alignments.pl -xml_dirs ${xml_dirs} -output_dir ${output_dir}
