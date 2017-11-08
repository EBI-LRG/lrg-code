#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

input_dir=$1
prod_only=$2

if [[ -z ${input_dir} ]]; then
  echo "No input dir defined!"
  exit
fi

json_file='lrg_index.json'
step_json_file='step_index.json'
json_dir='json_index'

perldir=${LRGROOTDIR}/lrg-code/scripts/


become ${WEBADMIN} bash << EOF

  if [ -z "$prod_only" ] || [ $prod_only == 2 ];then
    # DEV website
    cd ${DEVWEBSITE}
    rm -rf ./*
    cp -R ${input_dir}/* ./
    cp ${PUBFTP}/.lrg_index/${json_file} ./${json_dir}/
    cp ${PUBFTP}/.lrg_index/${step_json_file} ./${json_dir}/
    
    echo "Copy to the DEV website done"
  fi
  
  if  [ -z "$prod_only" ] || [ $prod_only == 1 ];then
    # Fallback website
    cd ${FBWEBSITE}
    rm -rf ./*
    cp -R ${input_dir}/* ./
    cp ${PUBFTP}/.lrg_index/${json_file} ./${json_dir}/
    cp ${PUBFTP}/.lrg_index/${step_json_file} ./${json_dir}/
  
    # PROD website
    scp -r ${FBWEBSITE}* ${WEBADMIN}@${PRODVM}:${PRODWEBSITE}/ 1> /dev/null
    
    echo "Copy to the PROD websites done"
  fi
exit
EOF
