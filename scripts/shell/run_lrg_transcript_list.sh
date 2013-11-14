#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

path=''
if [[ $1 ]]; then
  path="-xml_dir $1"
fi

tmpdir="-tmp_dir ${CVSROOTDIR}"
if [[ $2 ]]; then
  tmpdir="-tmp_dir $2"
fi

perl ${CVSROOTDIR}/code/scripts/get_lrg_transcript_list.pl ${path} ${tmpdir}
