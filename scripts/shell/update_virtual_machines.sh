#! /bin/bash
. ~/.bashrc
. ~/.lrgpaths


output_file=$1 

if [[ ! ${output_file} ]]; then
  echo "No output file defined!"
  exit
fi

perldir=${LRGROOTDIR}/lrg-code/scripts/

# Copy the JSON LRG index
json_file='lrg_index.json'
json_input=${PUBFTP}/.lrg_index/${json_file}
bash ${perldir}/shell/copy_files_to_website.sh ${json_input} json_index ${json_file}

# Copy the LRG step JSON index
step_json_file='step_index.json'
step_json_input=${PUBFTP}/.lrg_index/${step_json_file}
bash ${perldir}/shell/copy_files_to_website.sh ${step_json_input} json_index ${step_json_file}

rm -f ${output_file}
