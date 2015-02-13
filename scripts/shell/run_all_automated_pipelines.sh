#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths


# Init the pipeline
init_pipeline.pl LRG::Pipeline::Pipeline_conf

db_name='lrg_automated_pipeline'
beekeeper="beekeeper.pl -url mysql://admin:${LRGDBPASS}@${LRGDBHOST}:${LRGDBPORT}/${db_name}"

# Sync the pipeline
${beekeeper} -sync

# Run the pipeline
${beekeeper} -loop
