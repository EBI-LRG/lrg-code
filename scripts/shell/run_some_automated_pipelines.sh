#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass

DATE=`date +%Y-%m-%d`

# Check if there are some files
if ls ${PVTFTP}/LRG_*.xml.${DATE} 1> /dev/null 2>&1; then

  # Init the sub pipeline
  init_pipeline.pl LRG::Pipeline::Pipeline_conf -run_sub_pipeline 1

  db_name='lrg_automated_pipeline'
  beekeeper="beekeeper.pl -url mysql://admin:${LRGDBPASS}@${LRGDBHOST}:${LRGDBPORT}/${db_name}"

  # Sync the pipeline
  ${beekeeper} -sync

  # Run the pipeline
  ${beekeeper} -loop
  
fi
