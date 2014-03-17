#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

# e.g. lrg-code/scripts/shell/run_test_full_pipelines.sh LRGs.txt xml_dir new_dir tmp_dir
# With LRGs.txt like:
# LRG_1	COL1A1	GRCh37	0
# LRG_5	LEPRE1	GRCh37	1
# ...

data_file=$1
xml_dir=$2
new_dir=$3
tmp_dir=$4
is_test_hc=$5      # Test the Ensembl annotations


if [[ -n ${is_test_hc} && ${is_test_hc} != 0 ]] ; then
  if [[ ${is_test_hc} == 'is_hc' ]]; then
    is_test_hc='-is_hc'
  else
    is_test_hc='-is_test'
  fi
else
  is_test_hc=''
fi

perldir=${CVSROOTDIR}/lrg-code/scripts

perl ${perldir}/manage_pipeline.pl -data_file ${data_file} -xml_dir ${xml_dir} -new_dir ${new_dir} -tmp_dir ${tmp_dir} ${is_test_hc}
