#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

path=''
if [[ $1 ]]; then
  path=$1
fi

# GRCh37
perl ${CVSROOTDIR}/lrg-code/scripts/get_lrg_list.pl -assembly GRCh37 -xml_dir ${path}

# GRCh38
perl ${CVSROOTDIR}/lrg-code/scripts/get_lrg_list.pl -assembly GRCh38 -xml_dir ${path}
