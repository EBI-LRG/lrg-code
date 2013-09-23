#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

# e.g. code/scripts/shell/run_test_full_pipelines.sh LRGs.txt xml_dir new_dir tmp_dir
# With LRGs.txt like:
# LRG_1	COL1A1	GRCh37	0
# LRG_5	LEPRE1	GRCh37	1
# ...

data_file=$1
xml_dir=$2
new_dir=$3
tmp_dir=$4
is_test=$5      # Test the Ensembl annotations


if [[ -n ${is_test} && ${is_test} != 0 ]] ; then
  is_test='-is_test'
else
  is_test=''
fi

perldir=${CVSROOTDIR}/code/scripts

perl ${perldir}/manage_pipeline.pl -data_file ${data_file} -xml_dir ${xml_dir} -new_dir ${new_dir} -tmp_dir ${tmp_dir} ${is_test}
