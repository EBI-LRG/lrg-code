#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

# e.g. lrg-code/scripts/shell/run_full_pipelines.sh LRGs.txt xml_dir new_dir tmp_dir
# With LRGs.txt like:
# LRG_1	COL1A1	GRCh37	0
# LRG_5	LEPRE1	GRCh37	1
# ...

data_file=$1
xml_dir=$2
new_dir=$3
tmp_dir=$4


bashdir=${CVSROOTDIR}/lrg-code/scripts/shell

bash ${bashdir}/run_full_pipelines.sh ${data_file} ${xml_dir} ${new_dir} ${tmp_dir} 'is_test'
