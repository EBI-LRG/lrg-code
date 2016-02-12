#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

path=''
if [[ $1 ]]; then
  path=" -xml_dir $1"
fi

tmpdir="-tmp_dir ${LRGROOTDIR}"
if [[ $2 ]]; then
  tmpdir="-tmp_dir $2"
fi

script=${LRGROOTDIR}/lrg-code/scripts/get_lrg_transcript_list.pl

# GRCh37
perl ${script} -assembly GRCh37${path} ${tmpdir}

# GRCh38
perl ${script} -assembly GRCh38${path} ${tmpdir}
