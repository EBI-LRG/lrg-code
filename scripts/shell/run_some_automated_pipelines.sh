#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
. ~/.lrgpass

# Check if there are some files
DATE=`date +%Y-%m-%d`

FILES=$PVTFTP/LRG_*.xml*

has_files=0

for file in $FILES
do
  fdate=`date +%Y-%m-%d -r $file`
  if [ $fdate == $DATE ]; then
    has_files=1
  fi
done

if [ $has_files == 1 ]; then

  # Init the sub pipeline
  init_pipeline.pl LRG::Pipeline::Pipeline_conf -run_sub_pipeline 1

  db_name='lrg_automated_pipeline'
  beekeeper="beekeeper.pl -url mysql://admin:${LRGDBPASS}@${LRGDBHOST}:${LRGDBPORT}/${db_name}"

  # Sync the pipeline
  ${beekeeper} -sync

  # Run the pipeline
  ${beekeeper} -loop
  
fi
