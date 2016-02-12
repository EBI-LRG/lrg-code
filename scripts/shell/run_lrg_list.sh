#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

xmldir=''
if [[ $1 ]]; then
  xmldir=" -xml_dir $1"
fi

script=${LRGROOTDIR}/lrg-code/scripts/get_lrg_list.pl

# GRCh37
perl ${script} -assembly GRCh37${xmldir}

# GRCh38
perl ${script} -assembly GRCh38${xmldir}
