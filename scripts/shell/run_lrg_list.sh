#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

path=''
if [[ $1 ]]; then
  path=$1
fi

perl ${CVSROOTDIR}/lrg-code/scripts/get_lrg_list.pl ${path}
