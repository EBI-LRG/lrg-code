#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

path=''
if [[ $1 ]]; then
  path="-xml_dir $1"
fi

perl ${CVSROOTDIR}/code/scripts/get_lrg_transcript_list.pl ${path}
