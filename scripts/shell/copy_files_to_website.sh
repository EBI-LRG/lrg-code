#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths
 
#index_file=${PUBFTP}/.lrg_index/lrg_index.json 
#progress_file=${LRGROOTDIR}/lrgs_progress_status.html 

input_file=$1 
output_dir=$2
output_file=$3

if [[ -z ${input_file} ]]; then
  echo "No input file defined!"
  exit
fi
if [[ -z ${output_dir} ]]; then
  echo "No output dir defined!"
  exit
fi
if [[ -z ${output_file} ]]; then
  output_file=""
fi

become ${WEBADMIN} bash << EOF
if [ -f ${input_file} ]; then
  if [ -s ${input_file} ]; then
    
    # Dev website
    if [ ! -d "${DEVWEBSITE}/${output_dir}/" ]; then
      mkdir ${DEVWEBSITE}/${output_dir}/
    fi
    cp ${input_file} ${DEVWEBSITE}/${output_dir}/${output_file}
    
    # Fallback website
    if [ ! -d "${FBWEBSITE}/${output_dir}/" ]; then
      mkdir ${FBWEBSITE}/${output_dir}/
    fi
    cp ${input_file} ${FBWEBSITE}/${output_dir}/${output_file}
    
    # Production website (assuming the correct directories exist)
    scp ${FBWEBSITE}/${output_dir}/${output_file} ${WEBADMIN}@${PRODVM}:${PRODWEBSITE}/${output_dir}/${output_file} 1> /dev/null

  else
    echo "The input file is empty!"
  fi
else
  echo "The given input file is not a file!"
fi

exit
EOF
