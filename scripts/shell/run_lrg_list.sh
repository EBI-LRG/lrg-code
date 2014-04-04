#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

xmldir=''
if [[ $1 ]]; then
  xmldir="-xml_dir $1"
fi

# GRCh37
perl ${CVSROOTDIR}/lrg-code/scripts/get_lrg_list.pl -assembly GRCh37 ${xmldir}

# GRCh38
perl ${CVSROOTDIR}/lrg-code/scripts/get_lrg_list.pl -assembly GRCh38 ${xmldir}
