#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

# e.g. code/scripts/shell/run_full_pipelines.sh LRGs.txt xml_dir new_dir tmp_dir
# With LRGs.txt like:
# LRG_1	COL1A1	GRCh37	0
# LRG_5	LEPRE1	GRCh37	1
# ...

data_file=$1
xml_dir=$2
new_dir=$3
tmp_dir=$4
skip_check0=$5  # Skip primary HealthCheck (check existing LRG in the EBI FTP site)

if [ ${skip_check0} ] ; then
  skip_check0='1'
else
  skip_check0='0'
fi

bashdir=${CVSROOTDIR}/code/scripts/shell

bash ${bashdir}/run_full_pipelines.sh ${data_file} ${xml_dir} ${new_dir} ${tmp_dir} ${skip_check0} 'is_test'
