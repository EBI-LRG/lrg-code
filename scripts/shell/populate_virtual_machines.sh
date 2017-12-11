#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths

input_dir=$1
prod_only=$2

if [[ -z ${input_dir} ]]; then
  echo "No input dir defined!"
  exit
fi

indexes_dir='indexes'
ftp_dir=${PUBFTP}/.lrg_index/
files=('lrg_index.json' 'step_index.json' 'lrg_search_terms.txt')
files_with_path=()

for FILE in "${files[@]}"
do
  files_with_path+=("${ftp_dir}${FILE}")
done

perldir=${LRGROOTDIR}/lrg-code/scripts/


become ${WEBADMIN} bash << EOF

  if [ -z "$prod_only" ] || [ $prod_only == 2 ];then
    # DEV website
    cd ${DEVWEBSITE}
    rm -rf ./*
    cp -R ${input_dir}/* ./
    
    cp ${files_with_path[0]} ./${indexes_dir}/
    cp ${files_with_path[1]} ./${indexes_dir}/
    cp ${files_with_path[2]} ./${indexes_dir}/
    
    echo "Copy to the DEV website done"
  fi
  
  if  [ -z "$prod_only" ] || [ $prod_only == 1 ];then
    # Fallback website
    cd ${FBWEBSITE}
    rm -rf ./*
    cp -R ${input_dir}/* ./
    
    cp ${files_with_path[0]} ./${indexes_dir}/
    cp ${files_with_path[1]} ./${indexes_dir}/
    cp ${files_with_path[2]} ./${indexes_dir}/
  
    # PROD website
    scp -r ${FBWEBSITE}* ${WEBADMIN}@${PRODVM}:${PRODWEBSITE}/ 1> /dev/null
    
    echo "Copy to the PROD websites done"
  fi
exit
EOF
