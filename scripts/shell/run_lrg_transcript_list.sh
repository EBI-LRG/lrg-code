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

# GRCh37
perl ${CVSROOTDIR}/lrg-code/scripts/get_lrg_transcript_list.pl -assembly GRCh37 ${path} ${tmpdir}

# GRCh38
perl ${CVSROOTDIR}/lrg-code/scripts/get_lrg_transcript_list.pl -assembly GRCh38 ${path} ${tmpdir}
