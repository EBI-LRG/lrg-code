#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

# e.g. code/scripts/shell/run_full_pipelines.sh LRGs.txt xml_dir new_dir tmp_dir
# With LRGs.txt like:
# LRG_1	COL1A1	GRCh37
# LRG_5	LEPRE1	GRCh37
# ...

data_file=$1
xml_dir=$2
new_dir=$3
tmp_dir=$4
skip_check0=$5

if [ ${skip_check0} ] ; then
  skip_check0='-skip_check0'
else
  skip_check0=''
fi

perldir=${CVSROOTDIR}/code/scripts/

perl ${perldir}/manage_pipeline.pl -data_file ${data_file} -xml_dir ${xml_dir} -new_dir ${new_dir} -tmp_dir ${tmp_dir} ${skip_check0}