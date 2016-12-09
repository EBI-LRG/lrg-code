#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

input_dir=$1 

if [[ -z ${input_dir} ]]; then
  echo "No input dir defined!"
  exit
fi

json_file='lrg_index.json'
json_dir='json_index'

become ${WEBADMIN} bash << EOF

  # DEV website
  cd ${DEVWEBSITE}
  rm -rf ./*
  cp -R ${input_dir}/* ./
  cp ${PUBFTP}/.lrg_index/${json_file} ./${json_dir}/

  # Fallback website
  cd ${FBWEBSITE}
  rm -rf ./*
  cp -R ${input_dir}/* ./
  cp ${PUBFTP}/.lrg_index/${json_file} ./${json_dir}/
  
  # PROD website
  scp -r ${FBWEBSITE}* ${WEBADMIN}@${PRODVM}:${PRODWEBSITE}/ 1> /dev/null
  
exit
EOF
