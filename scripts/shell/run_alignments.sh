#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths


xml_dirs=$1
output_dir=$2

perldir=${CVSROOTDIR}/lrg-code/scripts/align

perl ${perldir}/generate_transcript_alignments.pl -xml_dirs ${xml_dirs} -output_dir ${output_dir}
