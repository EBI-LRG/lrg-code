#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

# e.g. lrg-code/scripts/shell/run_full_healthchecks_pipelines.sh LRGs.txt xml_dir tmp_dir
# With LRGs.txt like:
# LRG_1	COL1A1	GRCh37
# LRG_5	LEPRE1	GRCh37
# ...

data_file=$1
xml_dir=$2
tmp_dir=$3

bashdir=${LRGROOTDIR}/lrg-code/scripts/shell

bash ${bashdir}/run_full_pipelines.sh ${data_file} ${xml_dir} 'none' ${tmp_dir} 'is_hc'
